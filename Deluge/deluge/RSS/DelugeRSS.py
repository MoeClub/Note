#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

import os, re, gc, sqlite3, base64, time, json
from lxml import etree
from urllib import request
from deluge_client import DelugeRPCClient


Refresh_sec = '96'    # Time(s)
Free_Space = '20'    # GB
Ratio_Complete_Time = '80/2/5/100'    # 80/2/5; Complete_Ratio=80%; MinSpeed/Hour=2G/h; Hours_After=5h; Ignore_Size:100G; Disable: '0/0/0/0'
File_Max_Size = '0'    # GB
Torrent_Min_Size = '0'    # GB
Torrent_Max_Size = '64'    # GB
Torrent_Max_Time = '3.5'    # Days
Torrent_Max_Ratio = '3'
Download_Path = '/home/www/home'


Spider_dict = {
    'MT': {
        'Enable': True,
        'SavePath_ID': False,
        'URL': ['', ],
        'Download_URL': '',
        'Cookie': ''
    },
}


class Deluge:
    def __init__(self, host='127.0.0.1', port='58846'):
        self.path = os.path.dirname(os.path.abspath(__file__))
        self.host = host
        self.port = port

    def auth(self):
        auth_file = os.path.join(self.path, "auth")
        if not os.path.exists(auth_file):
            raise Exception
        fd = open(auth_file, 'r', encoding='utf8')
        client = None
        for line in fd:
            if line.startswith("#"):
                continue
            auth = line.split(":")
            if len(auth) >= 2 and auth[0] == "localclient":
                client = DelugeRPCClient(str(self.host), int(self.port), auth[0], auth[1], automatic_reconnect=False)
                break
        fd.close()
        return client

    def online(self, client):
        if not client.connected:
            try:
                client.connect()
                if not client.connected:
                    print('%s:%s CONNECT FAIL.' % (self.host, self.port))
                    return False
            except:
                print('%s:%s NOT TO CONNECT.' % (self.host, self.port))
                return False
        return True

    def add_task(self, client, task, option={}):
        if self.online(client):
            if not isinstance(option, dict):
                option = {}
            return client.call('core.add_torrent_file', '', task, option)
        else:
            return False

    def free_space(self, client, free='0', path=None):
        if self.online(client):
            reserve_space_total = 0
            status = client.call('core.get_torrents_status', {}, ['progress', 'total_size'])
            for torrent in status:
                reserve_space = int(status[torrent][b'total_size'] * (100 - float(status[torrent][b'progress'])) / 100)
                reserve_space_total += reserve_space
            free_space_client = client.call('core.get_free_space', path)
            free_space_reserve = int(float(free) * 1024 * 1024 * 1024)
            really_space = int(free_space_client - reserve_space_total - free_space_reserve)
            if really_space > 0:
                return really_space
            else:
                return False
        else:
            return False

    def torrents_status(self, client, Torrent_Max_Ratio, Torrent_Max_Time, Ratio_Complete_Time):
        if self.online(client):
            return_list = []
            try:
                RCT = [int(RCT_Item) for RCT_Item in str(Ratio_Complete_Time).split('/')]
                assert len(RCT) == 4
            except:
                RCT = [0, 0, 0, 0]
            result_dict = client.call('core.get_torrents_status', {}, ['progress', 'time_added', 'ratio', 'total_done', 'total_wanted'])
            time_now = int(time.time())
            for item in result_dict:
                time_cost = int(time_now - int(result_dict[item][b'time_added']))
                done_progress = int(result_dict[item][b'progress'])
                if done_progress == int(100):
                    if time_cost >= int(float(Torrent_Max_Time) * 86400) or float(result_dict[item][b'ratio']) >= float(Torrent_Max_Ratio):
                        return_list.append(str(item.decode()))
                else:
                    if RCT[0] > 0 and RCT[1] > 0 and RCT[2] > 0:
                        if int(RCT[3]) > 0 and int(result_dict[item][b'total_wanted']) >= int(RCT[3] * 1024 * 1024 * 1024):
                            continue
                        if time_cost > int(RCT[2] * 3600) and int(RCT[0]) > done_progress:
                            if int(int(result_dict[item][b'total_done']) / time_cost) < int(RCT[1] * 1024 * 1024 * 1024 / 3600):
                                return_list.append(str(item.decode()))
            del result_dict
            return return_list
        else:
            return False

    def remove_torrents(self, client, id_list=[], remove_data=False):
        if isinstance(id_list, bool) and id_list is False:
            return False
        if self.online(client):
            if isinstance(id_list, list) and len(id_list) > 0:
                for id_hash in id_list:
                    client.call('core.remove_torrent', id_hash, remove_data)


class Spider:
    def __init__(self, URL='', Cookie='', Download_URL='', datatable='', database='DelugeRSS.db', Save_Id=False, charset='utf-8'):
        self.path = os.path.dirname(os.path.abspath(__file__))
        self.database = os.path.join(self.path, database)
        self.URL = URL
        self.Cookie = Cookie
        self.datatable = datatable
        self.download_url = Download_URL
        self.charset = charset
        self.save_id = Save_Id
        self.http_timeout = 8

        conn = sqlite3.connect(self.database, timeout=1)
        cursor = conn.cursor()
        # status 0: False, 1: True
        sql = '''create table if not exists ''' + self.datatable + ''' (item_id int PRIMARY KEY, status int);'''
        cursor.execute(sql)
        conn.commit()
        conn.close()

        self.Header = {'User-Agent': 'Mozilla/5.0', 'Cookie': str(self.Cookie)}
        self.req = request.Request(self.URL, headers=self.Header)

    def get_item(self):
        item_list = []
        try:
            page = request.urlopen(self.req, timeout=self.http_timeout).read().decode(self.charset, "ignore")
            if 'logout.php' not in page:
                print('[%s] Login Fail! ' % self.datatable)
                raise Exception
        except:
            return item_list
        html = etree.HTML(page)
        try:
            ratio = str(html.xpath('//*[@class="color_ratio"]/following::text()[1]')[0])
            if ratio:
                print('[%s] Ratio: %s' % (self.datatable, ratio))
        except:
            print('[%s] Ratio: Null' % self.datatable)
        for href in html.xpath('//a[contains(@href, "download.php")]'):
            try:
                item_id = re.findall('id=[0-9]+|hash=[0-9a-zA-Z,_\-]+', href.attrib['href'], re.I)[0].split('=')[1]
                if item_id not in item_list:
                    item_list.append(item_id)
            except:
                try:
                    item_id = re.findall('id=[0-9]+|hash=[0-9a-zA-Z,_\-]+', href.attrib['action'], re.I)[0].split('=')[1]
                    if item_id not in item_list:
                        item_list.append(item_id)
                except:
                    continue
        del html
        del page
        return item_list

    def check_item(self, item_id):
        conn = sqlite3.connect(self.database, timeout=1)
        cursor = conn.cursor()
        sql = '''select status FROM ''' + self.datatable + ''' WHERE item_id=''' + str(item_id) + ''';'''
        cursor.execute(sql)
        res = cursor.fetchone()
        conn.close()
        if res:
            if res[0] > 0:
                return True
            else:
                return False
        else:
            return False

    def add_item(self, item_id, status):
        conn = sqlite3.connect(self.database, timeout=1)
        cursor = conn.cursor()
        sql = '''INSERT INTO ''' + self.datatable + ''' VALUES (''' + str(item_id) + ''', ''' + str(status) + ''');'''
        cursor.execute(sql)
        row = cursor.rowcount
        conn.commit()
        conn.close()
        if row >= 1:
            return True
        else:
            return False

    def data_item(self, item_id):
        torrent_URL = str(self.download_url) + str(item_id)
        torrent_req = request.Request(torrent_URL, headers=self.Header)
        torrent_data = request.urlopen(torrent_req, timeout=self.http_timeout).read()
        return base64.b64encode(torrent_data)

    def exec_item(self):
        item_continue = True
        item_list = self.get_item()
        if not isinstance(item_list, list):
            raise Exception
        for item_id in item_list:
            if not item_continue:
                break
            if not self.check_item(item_id):
                try:
                    torrent_base64 = self.data_item(item_id)
                    torrent_info = utils.torrent_info(torrent_base64, Torrent_Max_Size, Torrent_Min_Size, File_Max_Size)
                except:
                    continue
                disk_free_space = deluge.free_space(client, Free_Space)
                if isinstance(disk_free_space, bool) and disk_free_space is False:
                    item_continue = False
                    print('Error! Get disk space. ')
                    continue
                if not torrent_info['over_max']:
                    if disk_free_space > torrent_info['size']:
                        try:
                            if '/' not in str(Download_Path) or not str(Download_Path).startswith('/'):
                                raise Exception
                            if self.save_id:
                                option = '{"download_location":"' + str(Download_Path) + '/' + str(item_id) + '"}'
                            else:
                                option = '{"download_location":"' + str(Download_Path) + '"}'
                            option = json.loads(re.sub('/+', '/', option))
                        except:
                            option = {}
                        task = deluge.add_task(client, torrent_base64, option)
                        # task = 'task_debug'
                    else:
                        task = 'task_full'
                else:
                    task = 'task_big'
                if task != None:
                    if task == 'task_full':
                        print('%s[skip_full]: %s' % (self.datatable, item_id))
                    elif task == 'task_big':
                        self.add_item(item_id, 2)
                        print('%s[skip_big]: %s' % (self.datatable, item_id))
                    else:
                        self.add_item(item_id, 1)
                        print('%s[success]: %s' % (self.datatable, item_id))
                else:
                    self.add_item(item_id, 1)
                    print('%s[already]: %s' %(self.datatable, item_id))
                del torrent_base64


class Utils:
    def __init__(self):
        self.path = os.path.dirname(os.path.abspath(__file__))

    def free_cache(self):
        gc.collect()
        cache_path = '/proc/sys/vm/drop_caches'
        if os.path.exists(cache_path):
            os.system('echo 3 > ' + cache_path)

    def torrent_read(self, torrent_name):
        torrent_path = os.path.join(self.path, torrent_name)
        if not os.path.exists(torrent_path):
            return None
        fd = open(torrent_path, 'rb')
        torrent_data = fd.read()
        fd.close()
        return base64.b64encode(torrent_data)

    def torrent_info(self, torrent_base64, Max_Torrent_Size='0', Min_Torrent_Size='0', Max_Single_Size='0'):
        torrent_size = 0
        torrent_item = 0
        status_list = []
        single_max_size_status = False
        torrent_max_size_status = False
        single_max_size = int(float(Max_Single_Size) * 1024 * 1024 * 1024)
        torrent_max_size = int(float(Max_Torrent_Size) * 1024 * 1024 * 1024)
        torrent_min_size = int(float(Min_Torrent_Size) * 1024 * 1024 * 1024)
        torrent_data = base64.b64decode(torrent_base64)
        for x_size in re.findall(b':lengthi\d+e', torrent_data):
            item_size = int(re.findall('\d+', str(x_size))[0])
            if not single_max_size_status and single_max_size != 0 and item_size > single_max_size:
                single_max_size_status = True
            torrent_size += item_size
            torrent_item += 1
        status_list.append(torrent_max_size != 0 and torrent_size > torrent_max_size)
        status_list.append(torrent_min_size != 0 and torrent_size < torrent_min_size)
        if True in status_list:
            torrent_max_size_status = True
        return {'size': torrent_size, 'item': torrent_item, 'over_max': torrent_max_size_status, 'over_max_single': single_max_size_status}


if __name__ == "__main__":
    deluge = Deluge()
    utils = Utils()
    while True:
        client = deluge.auth()
        try:
            print('Time:', time.strftime('%Y/%m/%d %H:%M:%S', time.localtime()))
            for item in Spider_dict:
                if Spider_dict[item]['Enable']:
                    utils.free_cache()
                    print('Refreshing [%s] ...' % item)
                    for ItemURL in Spider_dict[item]['URL']:
                        try:
                            if not str(ItemURL).strip():
                                continue
                            spider = Spider(URL=str(ItemURL).strip(),  Cookie=str(Spider_dict[item]['Cookie']).strip(), Download_URL=str(Spider_dict[item]['Download_URL']).strip(), Save_Id=Spider_dict[item]['SavePath_ID'], datatable=str(item).strip())
                            spider.exec_item()
                            del spider
                        except:
                            print("Error! Task URL [%s]! " % item)
                else:
                    print('Refreshing [%s] skip! ' % item)
        except:
            print('Error! Task Exception. ')
        finally:
            print('Checking torrents ...')
            try:
                deluge.remove_torrents(client, deluge.torrents_status(client, Torrent_Max_Ratio, Torrent_Max_Time, Ratio_Complete_Time), True)
                del client
                utils.free_cache()
            except Exception as error:
                print('Error!', error)
            finally:
                print(str('Waitting refresh: {}\n').format(Refresh_sec))
                time.sleep(int(Refresh_sec))


