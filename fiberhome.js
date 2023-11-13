function encryptFunc(a, b, c) {
  var b = CryptoJS.enc.Utf8.parse(b);
  var c = CryptoJS.enc.Utf8.parse(c);
  var d = '';
  if (typeof a == 'string') {
    var e = CryptoJS.enc.Utf8.parse(a);
    d = CryptoJS.AES.encrypt(e, b, {
      iv: c,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7
    })
  } else if (typeof a == 'object') {
    data = JSON.stringify(a);
    var e = CryptoJS.enc.Utf8.parse(data);
    d = CryptoJS.AES.encrypt(e, b, {
      iv: c,
      mode: CryptoJS.mode.CBC,
      padding: CryptoJS.pad.Pkcs7
    })
  }
  return d.ciphertext.toString()
}

function decryptFunc(a, b, c) {
  var b = CryptoJS.enc.Utf8.parse(b);
  var c = CryptoJS.enc.Utf8.parse(c);
  var d = CryptoJS.enc.Hex.parse(a);
  var e = CryptoJS.enc.Base64.stringify(d);
  var f = CryptoJS.AES.decrypt(e, b, {
    iv: c,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  });
  var g = f.toString(CryptoJS.enc.Utf8);
  return g.toString()
}

function int_aes_iv() {
  var a = '';
  for (var i = 0; i < 16; i++) {
    a += String.fromCharCode(i + 112)
  }
  return a
}

function Session() {
  xhr = new XMLHttpRequest();
  tokenUrl = 'http://' + document.domain + '/api/tmp/FHNCAPIS?ajaxmethod=get_refresh_sessionid&' + '_=' + Math.random();
  xhr.open("GET", tokenUrl, false);
  xhr.send();
  if (xhr.status != 200) {
  	return null;
  }
  return JSON.parse(xhr.responseText).sessionid;
}

function Login(u, p) {
  if (u == undefined || p == undefined) {
  	u = "superadmin";
  	p = "F1ber$dm";
  }
  d = {"dataObj":{"username":u,"password":p},"ajaxmethod":"DO_WEB_LOGIN"};
  uri = "/api/sign/DO_WEB_LOGIN" + '?_=' + Math.random();
  return Post(d, uri);
}

function Post(d, uri) {
  if (uri === undefined) {
  	uri = "/api/tmp/FHAPIS" + '?_=' + Math.random();
  }
  if (document === undefined || document.domain === undefined) {
  	domain = "192.168.8.1";
  } else {
  	domain = document.domain;
  }
  sessionId = Session();
  if (sessionId === null) {
  	return "HTTP_NoSession";
  }
  iv = int_aes_iv();
  xhr = new XMLHttpRequest();
  apiUrl = 'http://' + domain + uri;
  xhr.open("POST", apiUrl, false);
  xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
  xhr.setRequestHeader('Accept', 'application/json, text/javascript, */*; q=0.01');
  xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8');
  k = sessionId.substring(0, 16);
  d.sessionid = sessionId;
  data = encryptFunc(d, k, iv);
  xhr.send(data);
  if (xhr.status != 200) {
  	return 'HTTP_' + xhr.status;
  }
  return decryptFunc(xhr.responseText, k, iv);
}

Login();
Post({"dataObj":{"MemoryTotal":"DeviceInfo.MemoryStatus.Total", "MemoryFree": "DeviceInfo.MemoryStatus.Free"},"ajaxmethod":"get_value_by_xmlnode"});
Post({"dataObj":{"KEY":"UPTIME"},"ajaxmethod":"get_cmd_result_web"});
Post({"dataObj":null,"ajaxmethod":"version_detection"});

