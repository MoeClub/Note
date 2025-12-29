#!/bin/bash
## https://github.com/monero-project/monero-gui/releases


PASSWD="${1:-}"
AMOUNT="${2:-0}"
TARGET="${3:-}"
BASE="${4:-Wallet}"
DECIMAL="100"
TXSEND=""
RPCServer=("xmr.support:18081" "nodes.hashvault.pro:18081" "moneronode.org:18081" "node1.xmr-tw.org:18081")


cd "$(dirname `readlink -f "$0"`)" || exit 1


[ "$AMOUNT" == "update" ] && {
  command -v wget >/dev/null || { apt -qqy update && apt install -qqy wget >/dev/null 2>&1 || exit 1; }
  command -v bzip2 >/dev/null || { apt -qqy update && apt install -qqy bzip2 >/dev/null 2>&1 || exit 1; }
  case `uname -m` in aarch64|arm64) ARCH="arm8";; x86_64|amd64) ARCH="64";; *) exit 1;; esac;
  [ -n "$ARCH" ] || exit 1
  url="https://downloads.getmonero.org/cli/linux${ARCH}"
  tmpPath=`mktemp -d`
  trap "rm -rf ${tmpPath}" EXIT
  wget --no-check-certificate -qO "${tmpPath}/monero.tar" "${url}" || exit 1
  tar -xvf "${tmpPath}/monero.tar" --strip-components=1 -C "${tmpPath}" 
  [ -f "${tmpPath}/monero-wallet-cli" ] || exit 1
  cp -rf "${tmpPath}/monero-wallet-cli" "./monero-wallet-cli" || exit 1
  chmod 777 "./monero-wallet-cli"
  exit "$?"
}


[ -f "./monero-wallet-cli" ] || exit 1

CheckRPC() {
  s="${1:-}"
  [ -n "$s" ] || return 2
  h=`echo "$s" |cut -d':' -f1 |sed 's/[[:space:]]//g'`
  p=`echo "$s" |cut -d':' -f2 |sed 's/[[:space:]]//g'`
  [ -n "$h" ] && [ -n "$p" ] || return 2
  nc -w 1 -z "$h" "$p" >/dev/null 2>&1
  return $?
}

RPC=""
for rpc in ${RPCServer[@]}; do CheckRPC "$rpc" && RPC="$rpc" && break; done
[ -n "$RPC" ] || exit 1

[ "$AMOUNT" == "new" ] && {
  result=`./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --generate-new-wallet "${BASE}" --password "${PASSWD}" --command="status"`
  address=`echo "$result" |grep "^Generated new wallet:" |cut -d':' -f2 |sed 's/[[:space:]]//g'`
  seed=`echo "$result" |grep -A4 '^NOTE:' |tail -n3 |sed ':a;N;$!ba;s/\n/ /g'`
  block=`echo "$result" |grep '^Refreshed' |cut -d',' -f1 |cut -d'/' -f2`
  [ -n "$address" ] && [ -n "$seed" ] && echo -e "\n\033[32mWallet Height\033[0m: \033[31m${block}\033[0m\n\033[32mWallet Address\033[0m: \033[31m${address}\033[0m\n\033[32mWallet Seed\033[0m: \033[31m${seed}\033[0m\n\n" && exit 0 || exit 1
}

[ "$AMOUNT" == "seed" ] && {
  echo -e "\n" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --generate-new-wallet "${BASE}" --password "${PASSWD}" --command="refresh" --restore-deterministic-wallet --electrum-seed="${TARGET}"
  exit "$?"
}

[ -f "./${BASE}" ] && [ -f "./${BASE}.keys" ] || exit 1
[ -n "${DECIMAL}" ] && [ "${DECIMAL}" -ge "1" ] || DECIMAL=1

[ "$AMOUNT" == "ui" -o "$AMOUNT" == "cli" ] && {
  ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}"
  exit $?
}

[ "$AMOUNT" == "out" ] && {
  echo -e "${PASSWD}" | ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="refresh" >/dev/null 2>&1
  echo -e "${PASSWD}" | ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="show_transfers" "out"  2>/dev/null |grep '[[:space:]]\+[0-9]\+[[:space:]]\+out[[:space:]]\+' |tail -n5
  exit $?
}

[ "$AMOUNT" == "in" ] && {
  echo -e "${PASSWD}" | ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="refresh" >/dev/null 2>&1
  echo -e "${PASSWD}" | ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="show_transfers" "in"  2>/dev/null |grep '[[:space:]]\+[0-9]\+[[:space:]]\+in[[:space:]]\+' |tail -n5
  exit $?
}


result=`echo -e "${PASSWD}" | ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="refresh" 2>/dev/null`
amount=`echo "$result" |grep '^Balance:' |cut -d',' -f2 |cut -d':' -f2 |grep -o '[0-9\.]*' |head -n1`
balance=`echo "$result" |grep '^Balance:' |cut -d',' -f1 |cut -d':' -f2 |grep -o '[0-9\.]*' |head -n1`
echo -e "[$(date '+%Y/%m/%d %H:%M:%S')]\nBalance: ${balance}\nUnlock: ${amount}"
[ -n "$amount" ] || exit 1
[ -n "$TARGET" ] || exit 2
AMOUNT=`echo "$AMOUNT" |grep -o '[0-9\.\-]*' |head -n1`
[ -n "$AMOUNT" ] || AMOUNT="0"
[ "$AMOUNT" == "0" ] && exit 0
_amount=`echo "${amount} ${DECIMAL}" |awk '{printf "%d", $1 * $2}'`
[ "$_amount" -eq "0" ] && exit 0
_AMOUNT=`echo "${AMOUNT} ${DECIMAL}" |awk '{printf "%d", $1 * $2}'`
[ "$_AMOUNT" -eq "0" ] && exit 0


[ "$AMOUNT" == "-1" ] && {
  txResult=`echo -e "${PASSWD}\nY" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="sweep_all" "${TARGET}"`
  realAMOUNT=`echo "$txResult" |grep -o '^Sweeping [0-9\.]*' |grep -o '[0-9\.]*' |head -n1`
}

[ "$AMOUNT" == "-2" ] && {
  realAMOUNT=`echo "${_amount} ${DECIMAL}" |awk '{printf "%.03f", $1 / $2}'`
  txResult=`echo -e "${PASSWD}\nY" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="transfer" "${TARGET}" "${realAMOUNT}"`
}

[ "$_AMOUNT" -gt "0" ] && {
  [ "$_AMOUNT" -le "$_amount" ] || exit 1
  realAMOUNT=`echo "${_AMOUNT} ${DECIMAL}" |awk '{printf "%.03f", $1 / $2}'`
  txResult=`echo -e "${PASSWD}\nY" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="transfer" "${TARGET}" "${realAMOUNT}"`
}

[ -n "$txResult" ] && {
  ErrorMSG=`echo "$txResult" |grep -o 'Error:.*'`
  [ -n "$ErrorMSG" ] && echo "$ErrorMSG" && exit 1
  TxID=`echo "$txResult" |grep -o 'Transaction successfully.*' |grep -o '<[0-9a-z]*>' |head -n1 |grep -o '[0-9a-z]*'`
  [ -n "$TxID" ] || exit 1
  echo -e "Sending: ${realAMOUNT} XMR --> ${TARGET}\nTxID[$(date '+%Y/%m/%d %H:%M:%S')]: ${TxID}\n"
  [ -n "${TXSEND}" ] && echo "[$(date '+%Y/%m/%d %H:%M:%S')] ${TxID} ${realAMOUNT} ${TARGET}" >>"${TXSEND}"
  exit 0
}
exit 1

