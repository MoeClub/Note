#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

# pip3 install rsa
# python3 OracleCreate.py -c "config/defaults.json" -i "create/defaults.json"

# config/defaults.json
# {
#   "compartmentId": "ocid1.tenancy...",
#   "userId": "ocid1.user...",
#   "URL": "https://iaas.xxxxx.oraclecloud.com/20160918/",
#   "certFinger": "ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff",
#   "certKey": "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
# }

# create/defaults.json
# {
#   "shape": "VM.Standard.E2.1.Micro",
#   "availabilityDomain": "flzu:AP-TOKYO-1-AD-1",
#   "subnetId": "ocid1.subnet...",
#   "imageId": "BASE64...",
#   "ssh_authorized_keys": "ssh-rsa ...",
# }


import hashlib
import datetime
import base64
import json
import time
import rsa
from urllib import request, error, parse


class oracle:
    @staticmethod
    def http(url, method, headers=None, data=None, coding='utf-8'):
        if not headers:
            headers = {}
        if data is not None:
            if isinstance(data, (dict, list)):
                data = json.dumps(data)
            if 'content-length' not in [str(item).lower() for item in list(headers.keys())]:
                headers['Content-Length'] = str(len(data))
            data = str(data).encode(coding)
        url_obj = request.Request(url, method=method, data=data, headers=headers)
        try:
            res_obj = request.urlopen(url_obj)
        except error.HTTPError as err:
            res_obj = err
        return res_obj

    @staticmethod
    def header(keyID, privateKey, reqURL, reqMethod, body=None, algorithm="rsa-sha256"):
        sign_list = []
        url_parse = parse.urlparse(reqURL)
        _header_field = ["(request-target)", "date", "host"]
        _header = {
            'host': str(url_parse.netloc),
            'user-agent': 'oracle-api/1.0',
            'date': str(datetime.datetime.utcnow().strftime("%a, %d %h %Y %H:%M:%S GMT")),
            'accept': '*/*',
            'accept-encoding': '',
        }
        sign_list.append(str("(request-target): {} {}").format(str(reqMethod).lower(), parse.quote_plus(str("{}{}").format(url_parse.path, str("?{}").format(url_parse.query) if url_parse.query else ""), safe="/?=&~")))
        if body is not None:
            if isinstance(body, (dict, list)):
                _body = json.dumps(body)
            else:
                _body = body
            _header_field += ["content-length", "content-type", "x-content-sha256"]
            _header['content-type'] = 'application/json'
            _header['content-length'] = str(len(_body))
            _header['x-content-sha256'] = str(base64.b64encode(hashlib.sha256(_body.encode("utf-8")).digest()).decode("utf-8"))
        sign_list += [str("{}: {}").format(item, _header[item]) for item in _header_field if "target" not in item]
        _signature = base64.b64encode(rsa.sign(str(str("\n").join(sign_list)).encode("utf-8"), rsa.PrivateKey.load_pkcs1(privateKey if isinstance(privateKey, bytes) else str(privateKey).strip().encode("utf-8")), str(algorithm).split("-", 1)[-1].upper().replace("SHA", "SHA-"))).decode("utf-8")
        _header['authorization'] = str('Signature keyId="{}",algorithm="{}",signature="{}",headers="{}"').format(keyID, algorithm, _signature, str(" ").join(_header_field))
        return _header

    @staticmethod
    def load_Key(file, BIN=False, coding='utf-8'):
        fd = open(file, 'r', encoding=coding)
        data = fd.read()
        fd.close()
        return str(data).strip().encode(coding) if BIN else str(data).strip()

    @staticmethod
    def load_Config(file, coding='utf-8'):
        fd = open(file, 'r', encoding=coding)
        data = fd.read()
        fd.close()
        return json.loads(data, encoding=coding)

    @classmethod
    def api(cls, method, url, keyID, privateKey, data=None):
        method_allow = ["GET", "HEAD", "DELETE", "PUT", "POST"]
        method = str(method).strip().upper()
        if method not in method_allow:
            raise Exception(str("Method Not Allow [{}]").format(method))
        if len(str(keyID).split("/")) != 3:
            raise Exception(str('Invalid "keyID"'))
        if method in ["PUT", "POST"] and data is None:
            data = ""
        privateKey = privateKey if isinstance(privateKey, bytes) else str(privateKey).strip().encode("utf-8")
        headers = cls.header(keyID, privateKey, url, method, data)
        return cls.http(url, method, headers, data)


class action:
    def __init__(self, apiDict, configDict):
        self.apiDict = apiDict
        self.configDict = configDict
        self.instancesDict = {
            'displayName': str(str(self.configDict["availabilityDomain"]).split(":", 1)[-1].split("-")[1]),
            'shape': self.configDict["shape"],
            'compartmentId': self.configDict["compartmentId"],
            'availabilityDomain': self.configDict["availabilityDomain"],
            'sourceDetails': {
                'sourceType': 'image',
                'imageId': self.configDict['imageId'],
            },
            'createVnicDetails': {
                'subnetId': self.configDict['subnetId'],
                'assignPublicIp': True
            },
            'metadata': {
                'user_data': self.configDict['user_data'],
                'ssh_authorized_keys': self.configDict['ssh_authorized_keys'],
            },
            'agentConfig': {
                'isMonitoringDisabled': False,
                'isManagementDisabled': False
            },
        }
        self.apiKey = "/".join([apiDict["compartmentId"], apiDict["userId"], apiDict["certFinger"]])
        self.url = self.apiDict["URL"] + "instances"
        self.body = json.dumps(self.instancesDict, ensure_ascii=False)

    def create(self, Full=True, WaitResource=True):
        while True:
            FLAG = False
            try:
                try:
                    response = oracle.api("POST", self.url, keyID=self.apiKey, privateKey=self.apiDict["certKey"], data=self.body)
                    response_json = json.loads(response.read().decode())
                    response_json["status_code"] = str(response.code)
                except Exception as e:
                    print(e)
                    response_json = {"code": "InternalError", "message": "Timeout.", "status_code": "555"}
                if str(response_json["status_code"]).startswith("4"):
                    FLAG = True
                    if str(response_json["status_code"]) == "401":
                        response_json["message"] = "Not Authenticated."
                    elif str(response_json["status_code"]) == "400":
                        if str(response_json["code"]) == "LimitExceeded":
                            response_json["message"] = "Limit Exceeded."
                        if str(response_json["code"]) == "QuotaExceeded":
                            response_json["message"] = "Quota Exceeded."
                    elif str(response_json["status_code"]) == "429":
                        FLAG = False
                    elif str(response_json["status_code"]) == "404":
                        if WaitResource and str(response_json["code"]) == "NotAuthorizedOrNotFound":
                            FLAG = False
                if int(response_json["status_code"]) < 300:
                    vm_ocid = str(str(response_json["id"]).split(".")[-1])
                    print(str("{} [{}] {}").format(time.strftime("[%Y/%m/%d %H:%M:%S]", time.localtime()), response_json["status_code"], str(vm_ocid[:5] + "..." + vm_ocid[-7:])))
                else:
                    print(str("{} [{}] {}").format(time.strftime("[%Y/%m/%d %H:%M:%S]", time.localtime()), response_json["status_code"], response_json["message"]))
                if Full is False and str(response_json["status_code"]) == "200":
                    FLAG = True
                if not FLAG:
                    if str(response_json["status_code"]) == "429":
                        time.sleep(60)
                    elif str(response_json["status_code"]) == "404":
                        time.sleep(30)
                    else:
                        time.sleep(5)
            except Exception as e:
                FLAG = True
                print(e)
            if FLAG:
                break


if __name__ == "__main__":
    def Exit(code=0, msg=None):
        if msg:
            print(msg)
        exit(code)

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', type=str, default="", help="Config Path")
    parser.add_argument('-i', type=str, default="", help="Instances Config Path")
    args = parser.parse_args()
    configPath = str(args.c).strip()
    configInstances = str(args.i).strip()

    if not configPath:
        Exit(1, "Require Config Path.")
    if not configInstances:
        Exit(1, "Require Instances Config Path.")

    Action = action(oracle.load_Config(configPath), oracle.load_Config(configInstances))
    Action.create()

    Exit(0)
