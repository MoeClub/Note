#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

# apt-get install -y python3-pip python3-cryptography
# pip3 install aiohttp aiohttp_socks
from aiohttp import client
from aiohttp_socks import ProxyConnector, ProxyType
from urllib import parse
import collections
import binascii
import base64
import asyncio
import hashlib
import hmac
import json
import time
import os


from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization, hashes, hmac
from cryptography.hazmat.primitives.asymmetric import rsa, ec, padding
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature


class DNS:
    @staticmethod
    def HUAWEI(name, sub: list, order: list, ttl=15, **kwargs):
        auth = None
        if "key" in kwargs and kwargs["key"] is not None and "secret" in kwargs and kwargs["secret"] is not None:
            auth = "key={}&secret={}".format(kwargs["key"], kwargs["secret"])
        if "token" in kwargs and kwargs["token"] is not None:
            auth = "token={}".format(kwargs["token"])
        if auth is None or auth == "":
            return []
        result = {}
        for item in order:
            if "domain" not in item or "txt" not in item:
                continue
            domain = str(item["domain"]).lstrip(name).strip(".")
            n = name
            for d in sub:
                if str(domain).endswith(d):
                    domain = d
                    n = str(item["domain"]).rstrip(d).strip(".")
                    break
            n_domain = str("{}_{}").format(n, domain)
            if n_domain not in result:
                result[n_domain] = {"domain": domain, "name": n, "txt": []}
            result[n_domain]["txt"].append(str('"{}"').format(item["txt"]))
        urls = []
        _urls = []
        for n_domain in result:
            data = base64.urlsafe_b64encode(json.dumps(result[n_domain]["txt"], separators=(",", ":"), ensure_ascii=False).encode()).decode()
            url = "https://api.moeclub.org/HWDNS?{}&action=add&target=record&domain={}&name={}&data={}&type={}&ttl={}".format(auth, result[n_domain]["domain"], result[n_domain]["name"], data, "TXT_BASE64", ttl)
            urls.append(url)
            _url = "https://api.moeclub.org/HWDNS?{}&action=del&target=record&domain={}&name={}&type={}".format(auth, result[n_domain]["domain"], result[n_domain]["name"], "TXT")
            _urls.append(_url)
        return urls, _urls


class ACME:
    ServerList = {
        "google": "https://dv.acme-v02.api.pki.goog/directory",
        "letsencrypt": "https://acme-v02.api.letsencrypt.org/directory",
    }

    Root = os.path.dirname(os.path.abspath(__file__))
    DNSHostValue = "_acme-challenge"
    Server = None
    Nonce = None
    AccountURL = None
    OrderURL = None
    OrderDetails = None
    PrivKey = None
    PrivateKeyPath = None
    CrtKey = None
    Crt = None
    JWKHash = None
    Challenges = list()
    DOMAIN = list()
    SUBDOMAIN = list()
    KWARGS = dict()

    def __init__(self, domain: (str, list), sub="", verify="dns", server="letsencrypt", rootData="acme", privKeyPath=None, privateKeyName="acme.key", ecc=True, proxy=None, **kwargs):
        self.KWARGS = kwargs
        self.Proxy = proxy
        self.server = server
        self.VerifyType = verify
        self.privKeyPath = privKeyPath
        self.PrivateKey = privateKeyName
        self.RootData = rootData
        self.ECC = True if ecc is True else False
        if domain is not None:
            if isinstance(domain, str):
                domain = str(domain).split(",")
            self.DOMAIN = [str(item).strip().strip(".").lower() for item in domain if "." in item]
        if isinstance(sub, str):
            sub = str(sub).split(",")
            self.SUBDOMAIN = [str(item).strip().strip(".").lower() for item in sub if "." in item]

    async def HTTP(self, method, url, headers=None, cookies=None, data=None, redirect=True, Proxy=None, timeout=30, loop=None):
        method = str(method).strip().upper()
        if method not in ["GET", "HEAD", "POST", "PUT", "DELETE", "PATCH"]:
            raise Exception(str("HTTP Method Not Allowed [{}].").format(method))
        if headers:
            Headers = {str(key).strip(): str(value).strip() for (key, value) in headers.items()}
        else:
            Headers = {"User-Agent": "Mozilla/5.0", "Accept-Encoding": ""}
        respData = {"code": None, "data": None, "headers": None, "cookies": None, "url": None, "req": None, "err": None}
        resp = None
        Connector = client.TCPConnector(ssl=False, force_close=True, enable_cleanup_closed=True, use_dns_cache=False)
        if Proxy is not None or str(Proxy).strip() != "":
            proxyParsed = parse.urlparse(str(Proxy).strip())
            if proxyParsed.scheme in ["socks5"]:
                proxyType = ProxyType.SOCKS5
            elif proxyParsed.scheme in ["socks4"]:
                proxyType = ProxyType.SOCKS4
            elif proxyParsed.scheme in ["http", "https"]:
                proxyType = ProxyType.HTTP
            else:
                proxyType = None
            if proxyType is not None:
                try:
                    username, password = (parse.unquote(proxyParsed.username), parse.unquote(proxyParsed.password))
                except:
                    username, password = ('', '')
                Connector = ProxyConnector(proxy_type=proxyType, host=proxyParsed.hostname, port=proxyParsed.port, username=username, password=password, rdns=None, ssl=False, force_close=True, enable_cleanup_closed=True, use_dns_cache=False)
        try:
            async with client.request(method=method, url=url, headers=Headers, cookies=cookies, data=data, timeout=client.ClientTimeout(total=timeout), allow_redirects=redirect, raise_for_status=False, connector=Connector, loop=loop) as resp:
                respData["data"] = await resp.read()
                respData["code"] = resp.status
                respData["headers"] = resp.headers
                respData["cookies"] = resp.cookies
                # respData["url"] = resp.url
                # respData["req"] = resp.request_info
        except Exception as e:
            if respData["code"] is None:
                respData["code"] = 555
            if respData["data"] is None:
                respData["data"] = b""
            respData["err"] = str(e)
        if Connector is not None:
            if Connector.closed is False:
                await Connector.close()
        if resp is not None:
            resp.close()
        del resp, Connector, headers, method, url, Proxy
        return respData

    async def SEND(self, url, protected, payload):
        body = dict()
        body["protected"] = protected
        body["payload"] = payload
        body["signature"] = self.Sign(key=self.PrivKey, data=str("{}.{}").format(body["protected"], body["payload"]).encode())
        resp = await self.HTTP("POST", url=url, headers=self.Headers(), data=json.dumps(body, separators=(',', ':'), ensure_ascii=False), redirect=False, Proxy=self.Proxy)
        if resp["code"] in [200, 201]:
            if "Replay-Nonce" in resp["headers"]:
                self.Nonce = resp["headers"]["Replay-Nonce"]
        return resp

    def ReadFile(self, f):
        if f is None:
            return None
        if os.path.sep not in f:
            f = os.path.join(self.Root, f)
        if not os.path.exists(f):
            return None
        fd = open(f, mode="r", encoding="utf-8")
        data = fd.read()
        fd.close()
        return data

    def WriteFile(self, f, d: (str, bytes), o=True):
        if os.path.sep not in f:
            f = os.path.join(self.Root, f)
        if o is False and os.path.exists(f):
            return True
        fdir = os.path.dirname(f)
        if not os.path.exists(fdir):
            os.makedirs(fdir)
        if isinstance(d, bytes):
            fd = open(f, mode="wb")
        else:
            fd = open(f, mode="w", encoding="utf-8")
        fd.write(d)
        fd.close()
        return True

    def Headers(self):
        return {
            "User-Agent": "ACME/1.0",
            "Accept-Encoding": "",
            "Accept-Language": "en",
            "Content-Type": "application/jose+json",
        }

    def SignHMAC(self, key: bytes, data: bytes, alg=hashes.SHA256()):
        h = hmac.HMAC(key, alg)
        h.update(data)
        return base64.urlsafe_b64encode(h.finalize()).decode().rstrip("=")

    def EncodeInt(self, i, bitSize=None):
        extend = 0
        if bitSize is not None:
            extend = ((bitSize + 7) // 8) * 2
        hi = hex(i).rstrip("L").lstrip("0x")
        hl = len(hi)
        if extend > hl:
            extend -= hl
        else:
            extend = hl % 2
        return binascii.unhexlify(extend * '0' + hi)

    def Sign(self, key, data, alg=hashes.SHA256()):
        if isinstance(key, (str, bytes)):
            privKey = serialization.load_pem_private_key(key if isinstance(key, bytes) else str(key).encode("utf-8"), password=None, backend=default_backend())
        else:
            privKey = key
        if hasattr(privKey, "curve"):
            signature = privKey.sign(data=data, signature_algorithm=ec.ECDSA(alg))
            r, s = decode_dss_signature(signature)
            signature = self.EncodeInt(r, privKey.curve.key_size) + self.EncodeInt(s, privKey.curve.key_size)
        else:
            signature = privKey.sign(data=data, padding=padding.PKCS1v15(), algorithm=alg)
        return base64.urlsafe_b64encode(signature).decode().rstrip("=")

    def JWK(self, privKey=None, ECC=True):
        if privKey is None:
            if ECC is True:
                privKey = ec.generate_private_key(curve=ec.SECP256R1(), backend=default_backend())
            else:
                privKey = rsa.generate_private_key(public_exponent=65537, key_size=2048, backend=default_backend())
        else:
            privKey = serialization.load_pem_private_key(data=privKey if isinstance(privKey, bytes) else str(privKey).encode(), password=None, backend=default_backend())
        privateKey = privKey.private_bytes(encoding=serialization.Encoding.PEM, format=serialization.PrivateFormat.PKCS8, encryption_algorithm=serialization.NoEncryption()).decode("utf-8").strip()
        pubKey = privKey.public_key()
        pubNum = pubKey.public_numbers()
        jwk = collections.OrderedDict()
        if hasattr(privKey, "curve"):
            jwk["crv"] = str("P-{}").format(512 if pubKey.curve.key_size == 521 else pubKey.curve.key_size)
            jwk["kty"] = 'EC'
            jwk["x"] = self.B64Encode(self.EncodeInt(pubNum.x, pubKey.curve.key_size))
            jwk["y"] = self.B64Encode(self.EncodeInt(pubNum.y, pubKey.curve.key_size))
        else:
            jwk["e"] = self.B64Encode(self.EncodeInt(pubNum.e, None))
            jwk["kty"] = 'RSA'
            jwk["n"] = self.B64Encode(self.EncodeInt(pubNum.n, None))
        jwkSHA256 = self.B64Encode(hashlib.sha256(json.dumps(jwk, separators=(",", ":"), ensure_ascii=False).encode()).digest())
        return privateKey, privKey, jwk, jwkSHA256

    def B64Encode(self, s):
        return base64.urlsafe_b64encode(s if isinstance(s, bytes) else str(s).encode()).decode().rstrip("=")

    def B64Decode(self, s):
        s += "="*((4 - len(s) % 4) % 4)
        return base64.urlsafe_b64decode(s)

    def CSR(self, domain: (str, list), privateKey=None):
        if privateKey is None or privateKey == "" or privateKey == b"":
            if self.ECC is True:
                privKey = ec.generate_private_key(curve=ec.SECP256R1(), backend=default_backend())
            else:
                privKey = rsa.generate_private_key(public_exponent=65537, key_size=2048, backend=default_backend())
        else:
            if isinstance(privateKey, (str, bytes)):
                privKey = serialization.load_pem_private_key(privateKey if isinstance(privateKey, bytes) else str(privateKey).encode("utf-8"), password=None, backend=default_backend())
            else:
                privKey = privateKey
        if isinstance(domain, str):
            domain = str(domain).split(",")
        domain = [str(item).strip() for item in domain if str(item).strip() != ""]
        if len(domain) == 0:
            return None, None
        builder = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([])).add_extension(x509.SubjectAlternativeName([x509.DNSName(item) for item in domain]), critical=False)
        csr = builder.sign(privKey, hashes.SHA256()).public_bytes(encoding=serialization.Encoding.PEM).decode("utf-8").strip()
        pKey = privKey.private_bytes(encoding=serialization.Encoding.PEM, format=serialization.PrivateFormat.PKCS8, encryption_algorithm=serialization.NoEncryption()).decode("utf-8").strip()
        return csr, pKey

    async def Init(self):
        if not str(self.server).startswith("https://"):
            if self.server not in self.ServerList:
                return False
            server = self.ServerList[self.server]
        resp = await self.HTTP("GET", url=server, headers=self.Headers(), redirect=False, Proxy=self.Proxy)
        if resp["code"] == 200:
            self.Server = json.loads(resp["data"].decode())
            if "Replay-Nonce" in resp["headers"]:
                self.Nonce = resp["headers"]["Replay-Nonce"]
            if self.Nonce is None:
                self.Nonce = await self.GetNonce()
            if self.privKeyPath is not None:
                if os.path.sep not in self.PrivateKeyPath:
                    self.PrivateKey = self.PrivateKeyPath
            self.PrivateKeyPath = os.path.join(self.Root, self.RootData, parse.urlparse(server).hostname, self.PrivateKey)
            return True
        return False

    async def GetNonce(self):
        if self.Server is None or "newNonce" not in self.Server:
            return None
        resp = await self.HTTP("HEAD", url=self.Server["newNonce"], headers=self.Headers(), redirect=False, Proxy=self.Proxy)
        if resp["code"] == 200 and "Replay-Nonce" in resp["headers"]:
            return resp["headers"]["Replay-Nonce"]
        return None

    async def GetAccount(self):
        if self.AccountURL is None:
            status = await self.Account()
            if status is not True:
                return False
        return True

    async def Account(self, mail=None, kid=None, hmacKey=None):
        if self.Server is None or self.Nonce is None:
            status = await self.Init()
            if status is not True:
                return False
        privateKey, self.PrivKey, jwk, self.JWKHash = self.JWK(privKey=self.ReadFile(f=self.PrivateKeyPath), ECC=self.ECC)
        payload = {
            "termsOfServiceAgreed": True,
        }
        if mail is not None and mail != "":
            payload["contact"] = ["mailto:{}".format(str(mail).strip().lower())]
        if "meta" in self.Server and "externalAccountRequired" in self.Server["meta"] and self.Server["meta"]["externalAccountRequired"] is True:
            if kid is not None and hmacKey is not None:
                payload["externalAccountBinding"] = dict()
                payload["externalAccountBinding"]["protected"] = self.B64Encode(json.dumps({"alg": "HS256", "kid": kid, "url": self.Server["newAccount"]}, separators=(', ', ': '), ensure_ascii=False))
                payload["externalAccountBinding"]["payload"] = self.B64Encode(json.dumps(jwk, separators=(', ', ': '), ensure_ascii=False))
                payload["externalAccountBinding"]["signature"] = self.SignHMAC(key=self.B64Decode(hmacKey), data=str("{}.{}").format(payload["externalAccountBinding"]["protected"], payload["externalAccountBinding"]["payload"]).encode())

        resp = await self.SEND(url=self.Server["newAccount"], protected=self.B64Encode(json.dumps({"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "jwk": jwk, "nonce": self.Nonce, "url": self.Server["newAccount"]}, separators=(', ', ': '), ensure_ascii=False)), payload=self.B64Encode(json.dumps(payload, separators=(', ', ': '), ensure_ascii=False)))
        if resp["code"] in [200, 201]:
            self.WriteFile(f=self.PrivateKeyPath, d=privateKey, o=False)
            if "Location" in resp["headers"]:
                self.AccountURL = resp["headers"]["Location"]
            return True
        return False

    async def Order(self, domain: (list, str) = None, verify=None):
        if not await self.GetAccount():
            return None

        if verify is None:
            verify = self.VerifyType
        verify = str(verify).strip().lower()
        if verify not in ["dns", "http", "tls-alpn"]:
            verify = "dns"
        self.VerifyType = verify

        if domain is not None:
            if isinstance(domain, str):
                domain = str(domain).split(",")
            domain = [str(item).strip() for item in domain if "." in item]
            self.DOMAIN = domain
        else:
            domain = self.DOMAIN
        payload = {"identifiers": []}
        for item in domain:
            payload["identifiers"].append({
                "type": verify,
                "value": item,
            })
        if len(payload["identifiers"]) <= 0:
            return None

        protected = {"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": self.Server['newOrder']}
        resp = await self.SEND(url=self.Server["newOrder"], protected=self.B64Encode(json.dumps(protected, separators=(', ', ': '), ensure_ascii=False)), payload=self.B64Encode(json.dumps(payload, separators=(', ', ': '), ensure_ascii=False)))
        if resp["code"] in [200, 201]:
            if "Location" in resp["headers"]:
                self.OrderURL = resp["headers"]["Location"]
            self.OrderDetails = json.loads(resp["data"].decode())
            if "status" in self.OrderDetails and self.OrderDetails["status"] in ["ready", "valid"]:
                return True
            if "authorizations" in self.OrderDetails:
                result = []
                for authUrl in self.OrderDetails["authorizations"]:
                    auth = await self.AuthChall(authUrl=authUrl)
                    if isinstance(auth, (tuple, list)):
                        result += auth
                result = [item for item in result if "type" in item and str(item["type"]).startswith("{}-".format(verify))]
                if len(result) == 0:
                    return None
                result = [item for item in result if "status" in item and item["status"] not in ["valid"]]
                self.Challenges = result
                if len(result) == 0:
                    return True
                for item in result:
                    if "error" in item and "detail" in item["error"]:
                        print('[{}] [{}] {} "{}" [{}]'.format(time.strftime("%Y/%m/%d %H:%M:%S", time.localtime()), item["type"], item["domain"], item["txt"], item["error"]["detail"]), flush=True)
                    else:
                        print('[{}] [{}] {} "{}"'.format(time.strftime("%Y/%m/%d %H:%M:%S", time.localtime()), item["type"], item["domain"] , item["txt"]), flush=True)
                return result
        return None

    async def AuthChall(self, authUrl):
        if authUrl is None or str(authUrl).strip() == "":
            return None
        if not await self.GetAccount():
            return None
        if self.OrderDetails is None or self.OrderURL is None:
            return None
        resp = await self.SEND(url=authUrl, protected=self.B64Encode(json.dumps({"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": authUrl}, separators=(', ', ': '), ensure_ascii=False)), payload="")
        if resp["code"] in [200, 201]:
            if "Replay-Nonce" in resp["headers"]:
                self.Nonce = resp["headers"]["Replay-Nonce"]
            respJson = json.loads(resp["data"].decode())
            if "identifier" in respJson and "value" in respJson["identifier"] and "status" in respJson:
                if "challenges" in respJson:
                    result = []
                    for item in respJson["challenges"]:
                        if item["status"] in ["valid"]:
                            continue
                        if "type" not in item or "token" not in item:
                            continue
                        value = str("{}.{}").format(item["token"], self.JWKHash)
                        if item["type"] in ['http-01']:
                            item["txt"] = value
                            item["domain"] = respJson["identifier"]["value"]
                        if item["type"] in ['dns-01', 'tls-alpn-01']:
                            item["txt"] = self.B64Encode(hashlib.sha256(value.encode()).digest())
                            item["domain"] = str("{}.{}").format(self.DNSHostValue, respJson["identifier"]["value"])
                        if "txt" not in item:
                            continue
                        result.append(item)
                    return result
                return True
        return None

    async def Chall(self, challUrl):
        if not await self.GetAccount():
            return None
        protected = {"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": challUrl}
        resp = await self.SEND(url=challUrl, protected=self.B64Encode(json.dumps(protected, separators=(', ', ': '), ensure_ascii=False)), payload="e30")
        if resp["code"] in [200, 201]:
            return True
        return False

    async def CheckChall(self, verify=None):
        if verify is None:
            verify = self.VerifyType
        if verify is None:
            verify = "dns"
        if not await self.GetAccount():
            return None
        if self.OrderDetails is None:
            return None
        if "status" in self.OrderDetails and self.OrderDetails["status"] in ["ready", "valid"]:
            return True
        if len(self.Challenges) == 0:
            return None
        valid = []
        for item in self.Challenges:
            if "url" not in item or "status" not in item:
                continue
            status = await self.Chall(challUrl=item["url"])
            if status is True:
                valid.append(item["url"])
        if len(valid) != len(self.Challenges):
            return None
        await asyncio.sleep(5)
        if "authorizations" in self.OrderDetails:
            result = []
            for authUrl in self.OrderDetails["authorizations"]:
                auth = await self.AuthChall(authUrl=authUrl)
                if isinstance(auth, (tuple, list)):
                    result += auth
            result = [item for item in result if "type" in item and str(item["type"]).startswith("{}-".format(verify)) and "status" in item and item["status"] not in ["valid"]]
            if len(result) == 0:
                return True
            for item in result:
                if "error" in item and "detail" in item["error"]:
                    print('[{}] [{}] {} "{}" [{}]'.format(time.strftime("%Y/%m/%d %H:%M:%S", time.localtime()), item["type"], item["domain"], item["txt"], item["error"]["detail"]), flush=True)
                else:
                    print('[{}] [{}] {} "{}"'.format(time.strftime("%Y/%m/%d %H:%M:%S", time.localtime()), item["type"], item["domain"] , item["txt"]), flush=True)
        return None

    async def Finalize(self, csr=None):
        if not await self.GetAccount():
            return None
        if self.OrderDetails is None:
            return None
        if csr is None:
            csr, self.CrtKey = self.CSR(domain=self.DOMAIN, privateKey=None)
        if "BEGIN CERTIFICATE REQUEST" in csr:
            csr = str(csr).replace("BEGIN CERTIFICATE REQUEST", "").replace("END CERTIFICATE REQUEST", "").replace("-", "").replace("\n", "").replace("/", "_").replace("+", "-").rstrip("=")
        protected = {"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": self.OrderDetails["finalize"]}
        payload = {"csr": csr}
        resp = await self.SEND(url=self.OrderDetails["finalize"], protected=self.B64Encode(json.dumps(protected, separators=(', ', ': '), ensure_ascii=False)), payload=self.B64Encode(json.dumps(payload, separators=(', ', ': '), ensure_ascii=False)))
        if resp["code"] in [200, 201]:
            return True
        return False

    async def FinalizeCrt(self, crtUrl):
        protected = {"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": crtUrl}
        resp = await self.SEND(url=crtUrl, protected=self.B64Encode(json.dumps(protected, separators=(', ', ': '), ensure_ascii=False)), payload="")
        if resp["code"] in [200, 201]:
            return resp["data"].decode()
        return None

    async def CheckOrder(self, csr=None):
        if not await self.GetAccount():
            return None
        if self.OrderDetails is None:
            return None
        for _ in range(15):
            protected = {"alg": "ES{}".format(self.PrivKey.curve.key_size) if hasattr(self.PrivKey, "curve") else "RS256", "kid": self.AccountURL, "nonce": self.Nonce, "url": self.OrderURL}
            resp = await self.SEND(url=self.OrderURL, protected=self.B64Encode(json.dumps(protected, separators=(', ', ': '), ensure_ascii=False)), payload="")
            if resp["code"] in [200, 201]:
                self.OrderDetails = json.loads(resp["data"].decode())
                if "status" in self.OrderDetails:
                    if self.OrderDetails["status"] in ["valid"]:
                        if "certificate" in self.OrderDetails:
                            self.Crt = await self.FinalizeCrt(crtUrl=self.OrderDetails["certificate"])
                            if self.Crt is not None:
                                break
                    if self.OrderDetails["status"] in ["ready"]:
                        status = await self.Finalize(csr=csr)
                        if status is False:
                            break
                    await asyncio.sleep(delay=6)
                    continue
        if self.Crt is not None and self.CrtKey is not None:
            # CrtMark = "{}_{}_{}".format(time.strftime("%Y%m%d%H%M%S", time.localtime()), "ecc" if self.ECC is True else "rsa", self.DOMAIN[0].replace("*", "").replace(".", "_").strip("_"))
            CrtMark = self.DOMAIN[0].replace("*", "").strip(".")
            CrtPath = os.path.join(self.Root, self.RootData, "crt", CrtMark)
            if not os.path.exists(CrtPath):
                os.makedirs(CrtPath)
            self.WriteFile(f=os.path.join(CrtPath, "server.crt.pem"), d=self.Crt, o=True)
            self.WriteFile(f=os.path.join(CrtPath, "server.key.pem"), d=self.CrtKey, o=True)
        return self.Crt, self.CrtKey

    async def NewCrt(self):
        order = await self.Order()
        if order is None:
            return None, None
        if isinstance(order, list) and len(order) > 0:
            for _ in range(5):
                # input("Wait...")
                urls, _urls = DNS.HUAWEI(name=self.DNSHostValue, sub=self.SUBDOMAIN, order=order, ttl=15, **self.KWARGS)
                for url in urls:
                    resp = await self.HTTP(method="GET", url=url, timeout=60, Proxy=self.Proxy)
                    print(json.dumps(json.loads(resp["data"].decode()), indent=4, ensure_ascii=False), flush=True)
                await asyncio.sleep(delay=15)
                status = await self.CheckChall()
                if status is True:
                    for url in _urls:
                        resp = await self.HTTP(method="GET", url=url, timeout=60, Proxy=self.Proxy)
                        print(json.dumps(json.loads(resp["data"].decode()), indent=4, ensure_ascii=False), flush=True)
                    break
        return await self.CheckOrder()



if __name__ == "__main__":
    # NewCrt: python3 acme.py -d "xxx.com,*.xxx.com"
    # NewCrt: python3 acme.py -d "sub.xxx.com,*.sub.xxx.com" -v dns -s google -sub "xxx.com" -ecc

    # Register: python3 acme.py -register -s google -mail "xyz@abc.com" -kid "<keyId>" -key "<hmacKey>"
    # Enable GTS: https://console.cloud.google.com/apis/library/publicca.googleapis.com
    # GTS HMAC KEY: gcloud publicca external-account-keys create
    ## gcloud config set project <project-name>; gcloud services enable publicca.googleapis.com

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', dest='domain', type=str, help='domains with comma separated.')
    parser.add_argument('-v', dest="verify", type=str, default="dns", help='http, dns.')
    parser.add_argument('-s', dest="server", type=str, default="letsencrypt", help='ca directory.')
    parser.add_argument('-ecc', dest="ecc", action="store_false", help='use ecc, default rsa.')
    parser.add_argument('-register', dest="register", action="store_true", help='register')
    parser.add_argument('-mail', dest="mail", type=str, help='mail, register')
    parser.add_argument('-kid', dest="kid", type=str, help='eab kid, register.')
    parser.add_argument('-key', dest="key", type=str, help='eab hmac key, register')
    parser.add_argument('-data', dest="data", type=str, default="acme", help='data directory')
    parser.add_argument('-sub', dest="sub", type=str, default="", help='declare sub domain with comma separated.')
    parser.add_argument('-proxy', dest="proxy", type=str, default=None, help='use proxy.')
    args = parser.parse_args()

    loop = asyncio.get_event_loop()
    acme = ACME(domain=args.domain, sub=args.sub, verify=args.verify, server=args.server, rootData=args.data, ecc=args.ecc, proxy=args.proxy, **{"key": None, "secret": None})
    if args.register is True:
        status = loop.run_until_complete(acme.Account(mail=args.mail, kid=args.kid, hmacKey=args.key))
        print("Register Status: {}".format(status))
        if status is True:
            print("Private Key: {}".format(acme.PrivateKeyPath))
    if len(acme.DOMAIN) == 0:
        os._exit(0)
    crt, key = loop.run_until_complete(acme.NewCrt())
    print(crt)
    print(key)









