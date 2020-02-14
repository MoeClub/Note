#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

# pip3 install rsa
# python3 OracleAction.py -c "config/defaults.json" -i "ocid1.instance...|create/defaults.json" -a "<action>" -n "name"
# https://docs.cloud.oracle.com/en-us/iaas/tools/public_ip_ranges.json

# config/defaults.json
# {
#   "compartmentId": "ocid1.tenancy...",
#   "userId": "ocid1.user...",
#   "URL": "https://iaas.xxx.oraclecloud.com/20160918/",
#   "certFinger": "ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff:ff",
#   "certKey": "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
# }

# create/defaults.json
# {
#   "shape": "VM.Standard.E2.1.Micro",
#   "availabilityDomain": "xx:XX",
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
    def __init__(self, apiDict, instancesId=None, configDict=None):
        self.apiDict = apiDict
        self.privateKey = self.apiDict["certKey"]
        self.apiKey = "/".join([self.apiDict["compartmentId"], self.apiDict["userId"], self.apiDict["certFinger"]])
        self.configDict = configDict
        self.instancesId = instancesId
        self.instancesDict = None
        self.VNIC = None
        self.PRIVATE = None

    def getPrivateIP(self):
        if not self.instancesId:
            print("Require instancesId.")
            exit(1)
        url = self.apiDict["URL"] + "vnicAttachments?instanceId=" + self.instancesId + "&compartmentId=" + self.apiDict["compartmentId"]
        response = oracle.api("GET", url, keyID=self.apiKey, privateKey=self.privateKey)
        response_vnic = json.loads(response.read().decode())
        if response_vnic:
            self.VNIC = response_vnic[0]
        if not self.VNIC:
            print("Not Found VNIC.")
            exit(1)

        url = self.apiDict["URL"] + "privateIps?vnicId=" + self.VNIC["vnicId"]
        response = oracle.api("GET", url, keyID=self.apiKey, privateKey=self.privateKey)
        response_private = json.loads(response.read().decode())
        if response_private:
            for privateIp in response_private:
                if privateIp["isPrimary"]:
                    self.PRIVATE = response_private[0]
                    break
        if not self.PRIVATE:
            print("Not Found Private IP Address.")
            exit(1)

    def getPublicIP(self):
        url = self.apiDict["URL"] + "publicIps/actions/getByPrivateIpId"
        BodyOne = json.dumps({"privateIpId": self.PRIVATE["id"]}, ensure_ascii=False)
        response = oracle.api("POST", url, keyID=self.apiKey, privateKey=self.privateKey, data=BodyOne)
        if response.code >= 200 and response.code < 400:
            response_public = json.loads(response.read().decode())
            return response_public
        elif response.code >= 400 and response.code < 500:
            return None
        else:
            print("Server Error. [%s]" % response.code)
            exit(1)

    def delPublicIP(self, publicIp):
        url = self.apiDict["URL"] + "publicIps/" + publicIp
        oracle.api("DELETE", url, keyID=self.apiKey, privateKey=self.privateKey)

    def newPublicIP(self):
        bodyTwo = {
            "lifetime": "EPHEMERAL",
            "compartmentId": self.apiDict["compartmentId"],
            "privateIpId": self.PRIVATE["id"],
        }
        url = self.apiDict["URL"] + "publicIps"
        BodyTwo = json.dumps(bodyTwo, ensure_ascii=False)
        response = oracle.api("POST", url, keyID=self.apiKey, privateKey=self.privateKey, data=BodyTwo)
        NewPublic = json.loads(response.read().decode())
        print("PublicIP:", NewPublic["ipAddress"])
        return NewPublic

    def showPublicIP(self):
        self.getPrivateIP()
        PUBLIC = self.getPublicIP()
        publicIp = "NULL"
        if PUBLIC:
            publicIp = PUBLIC["ipAddress"]
        print("PublicIP: %s" % publicIp)
        return PUBLIC

    def changePubilcIP(self):
        self.getPrivateIP()
        PUBLIC = self.getPublicIP()
        publicIp = "NULL"
        if PUBLIC:
            publicIp = PUBLIC["ipAddress"]
            self.delPublicIP(PUBLIC["id"])
        print("PublicIP[*]: %s" % publicIp)
        PUBLIC = self.newPublicIP()
        return PUBLIC

    def rename(self, newName, DisableMonitoring=True):
        if not self.instancesId:
            print("Require instancesId.")
            exit(1)
        setName = str(newName).strip()
        if not setName:
            print("Name Invalid.")
            exit(1)
        body = {"displayName": setName, "agentConfig": {"isMonitoringDisabled": DisableMonitoring}}
        url = self.apiDict["URL"] + "instances/" + self.instancesId
        Body = json.dumps(body, ensure_ascii=False)
        response = oracle.api("PUT", url, keyID=self.apiKey, privateKey=self.privateKey, data=Body)
        response_json = json.loads(response.read().decode())
        response_json["status_code"] = str(response.code)
        print(json.dumps(response_json, indent=4))

    def createInstancesPre(self, Name=None):
        self.instancesDict = {
            'displayName': str(str(self.configDict["availabilityDomain"]).split(":", 1)[-1].split("-")[1]),
            'shape': self.configDict["shape"],
            'compartmentId': self.apiDict["compartmentId"],
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
        if Name and str(Name).strip():
            self.instancesDict['displayName'] = str(Name).strip()

    def createInstances(self, Name=None, Full=True, WaitResource=True):
        url = self.apiDict["URL"] + "instances"
        if not self.instancesDict or Name is not None:
            self.createInstancesPre(Name=Name)
        body = json.dumps(self.instancesDict, ensure_ascii=False)
        while True:
            FLAG = False
            try:
                try:
                    response = oracle.api("POST", url, keyID=self.apiKey, privateKey=self.privateKey, data=body)
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
    parser.add_argument('-i', type=str, default="", help="Instances Id or Instances Config Path")
    parser.add_argument('-n', type=str, default="", help="New Instances Name")
    parser.add_argument('-p', type=str, default="", help="IP Address Prefix")
    parser.add_argument('-a', type=str, default="", help="Action [show, change, rename, create, target]")
    args = parser.parse_args()
    configPath = str(args.c).strip()
    configAction = str(args.a).strip().lower()
    configInstancesId = str(args.i).strip()
    configInstancesName = str(args.n).strip()
    configAddress = str(args.p).strip()
    configActionList = ["show", "change", "rename", "create", "target"]

    if not configPath:
        Exit(1, "Require Config Path.")
    if not configAction or configAction not in configActionList:
        Exit(1, "Invalid Action.")
    if not configInstancesId:
        Exit(1, "Require Instances Id or Instances Config Path.")

    if configAction == "loop" and not configAddress:
        configAction = "change"

    if configAction == "show":
        Action = action(apiDict=oracle.load_Config(configPath), instancesId=configInstancesId)
        Action.showPublicIP()
    elif configAction == "change":
        Action = action(apiDict=oracle.load_Config(configPath), instancesId=configInstancesId)
        Action.changePubilcIP()
    elif configAction == "rename":
        if not configInstancesName:
            Exit(1, "Require Instances Name.")
        Action = action(apiDict=oracle.load_Config(configPath), instancesId=configInstancesId)
        Action.rename(configInstancesName)
    elif configAction == "create":
        if not configInstancesName:
            configInstancesName = None
        else:
            configInstancesName = str(configInstancesName).strip()
        Action = action(apiDict=oracle.load_Config(configPath), configDict=oracle.load_Config(configInstancesId))
        Action.createInstances(configInstancesName)
    elif configAction == "target":
        Action = action(apiDict=oracle.load_Config(configPath), instancesId=configInstancesId)
        while True:
            NewPublic = Action.changePubilcIP()
            if str(NewPublic["ipAddress"]).startswith(configAddress):
                break
            else:
                del NewPublic
                time.sleep(3)

    Exit(0)
