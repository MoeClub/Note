#!/bin/bash
## https://github.com/monero-project/monero-gui/releases

PASSWD="${1:-}"
AMOUNT="${2:-0}"
TARGET="${3:-}"
BASE="${4:-Wallet}"
DECIMAL="1000"
TXSEND=""
RPC="xmr.support:18081"


cd "$(dirname `readlink -f "$0"`)" || exit 1


[ "$AMOUNT" == "update" ] && {
  command -v wget >/dev/null || { apt -qqy update && apt install -qqy wget || exit 1; }
  command -v bzip2 >/dev/null || { apt -qqy update && apt install -qqy bzip2 || exit 1; }
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

[ "$AMOUNT" == "new" ] && {
  result=`./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --generate-new-wallet "${BASE}" --password "${PASSWD}" --command="status"`
  address=`echo "$result" |grep "^Generated new wallet:" |cut -d':' -f2 |sed 's/[[:space:]]//g'`
  seed=`echo "$result" |grep -A4 '^NOTE:' |tail -n3 |sed ':a;N;$!ba;s/\n/ /g'`
  block=`echo "$result" |grep '^Refreshed' |cut -d',' -f1 |cut -d'/' -f2`
  [ -n "$address" ] && [ -n "$seed" ] && echo -e "\n\033[32mWallet Height\033[0m: \033[31m${block}\033[0m\n\033[32mWallet Address\033[0m: \033[31m${address}\033[0m\n\033[32mWallet Seed\033[0m: \033[31m${seed}\033[0m\n\n" && exit 0 || exit 1
}

[ "$AMOUNT" == "seed" ] && {
  ./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --generate-new-wallet "${BASE}" --password "${PASSWD}" --command="refresh" --restore-deterministic-wallet --electrum-seed="${TARGET}"
  exit "$?"
}

result=`./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="refresh" 2>/dev/null`
amount=`echo "$result" |grep '^Balance:' |cut -d',' -f1 |cut -d':' -f2 |sed 's/[[:space:]]//g' |head -n1`
unlock=`echo "$result" |grep '^Balance:' |cut -d',' -f2 |cut -d':' -f2 |sed 's/[[:space:]]//g' |head -n1`
echo -e "Balance:: ${amount}\nUnlock: ${unlock}"
[ -n "$amount" ] || exit 1
[ -n "$TARGET" ] || exit 2
[ -n "$AMOUNT" ] || AMOUNT="0"
_amount=`echo "${amount} ${DECIMAL}" |awk '{printf "%d", $1 * $2}'`
_AMOUNT=`echo "${AMOUNT} ${DECIMAL}" |awk '{printf "%d", $1 * $2}'`
[ "$_amount" -eq "0" ] && exit 0
[ "$_AMOUNT" -eq "0" ] && exit 0

[ "$AMOUNT" -eq "-1" ] && {
  result=`echo "${PASSWD}" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="sweep_all" "${TARGET}"`
}

[ "$_AMOUNT" -gt "0" ] && [ "$_AMOUNT" -le "$_amount" ] && {
  realAMOUNT=`echo "${_AMOUNT} ${DECIMAL}" |awk '{printf "%.03f", $1 / $2}'`
  result=`echo "${PASSWD}" |./monero-wallet-cli --mnemonic-language English --use-english-language-names --trusted-daemon --allow-mismatched-daemon-version --daemon-address "${RPC}" --log-file /dev/null --wallet-file "${BASE}" --password "${PASSWD}" --command="transfer" "${TARGET}" "${realAMOUNT}"`
}

echo "$result"
TxID=`echo "$result" |grep '^Transaction ID:' |grep -o '[0-9]\+'`
[ -n "$TxID" ] && {
  echo -e "Sending: ${AMOUNT} XTM --> ${TARGET}\nTxID[$(date '+%Y/%m/%d %H:%M:%S')]: ${TxID}\n"
  [ -n "${TXSEND}" ] && echo "[$(date '+%Y/%m/%d %H:%M:%S')] ${block} ${TxID} ${AMOUNT} ${TARGET}" >>"${TXSEND}"
  exit 0
}
exit 1

