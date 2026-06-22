#!/bin/bash

os=`python3 -c "import os; print(os.sys.platform)" 2>/dev/null`
[ -n "$os" ] || exit 1
target=`python3 -c "import importlib.util; print(importlib.util.find_spec('curl_cffi').origin)" 2>/dev/null`
[ -n "${target}" ] || exit 1
targetFile="${target%/*}/requests/session.py"
[ -f "${targetFile}" ] || exit 1
if [ "$os" == "darwin" ]; then
  sed -i '' 's/^\([[:space:]]*\)domain=morsel\.get("domain", "").*$/\1domain=morsel.get("domain", "") or urlparse(rsp.url).hostname,/' "${targetFile}"
else
  sed -i 's/^\([[:space:]]*\)domain=morsel\.get("domain", "").*$/\1domain=morsel.get("domain", "") or urlparse(rsp.url).hostname,/' "${targetFile}"
fi
exit $?
