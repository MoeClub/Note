#!/bin/bash
## https://github.com/tari-project/tari/releases

PASSWD="${1:-}"
AMOUNT="${2:-0}"
TARGET="${3:-}"
BASE="${4:-.tari}"
TARICMD=""


cd "$(dirname `readlink -f "$0"`)" || exit 1
[ -d "${BASE}/mainnet/libtor" ] && rm -rf "${BASE}/mainnet/libtor"
[ -d "${BASE}/mainnet/log" ] && rm -rf "${BASE}/mainnet/log"
[ -d "${BASE}/mainnet/peer_db" ] && rm -rf "${BASE}/mainnet/peer_db"


[ "$AMOUNT" == "update" ] && {
  command -v wget >/dev/null || exit 1
  command -v 7z >/dev/null || exit 1
  case `uname -m` in aarch64|arm64) ARCH="arm64";; x86_64|amd64) ARCH="x86_64";; *) exit 1;; esac;
  result=`wget --no-check-certificate -qO- "https://api.github.com/repos/tari-project/tari/releases/latest"`
  url=`echo "$result" |grep '"browser_download_url":' |grep 'tari_suite-[0-9]' |grep 'linux' |grep -v '.sha256' |grep "${ARCH}" |cut -d'"' -f4`
  [ -n "$url" ] || exit 1
  tmpPath=`mktemp -d`
  trap "rm -rf ${tmpPath}" EXIT
  wget --no-check-certificate -qO "${tmpPath}/tari_suite.zip" "${url}" || exit 1
  7z e "${tmpPath}/tari_suite.zip" "minotari_console_wallet" -o"${tmpPath}"
  [ -f "${tmpPath}/minotari_console_wallet" ] || exit 1
  cp -rf "${tmpPath}/minotari_console_wallet" "./minotari_console_wallet" || exit 1
  chmod 777 "./minotari_console_wallet"
  exit "$?"
}


[ -f "./minotari_console_wallet" ] || exit 1

[ "$AMOUNT" == "new" ] && {
  seedFile=`mktemp`; trap "rm -rf ${seedFile}" EXIT
  ./minotari_console_wallet --non-interactive-mode --network Mainnet --base-path "${BASE}" --seed-words-file-name "${seedFile}" --password "${PASSWD}"
  [ $? -eq 0 ] || exit 1
  rm -rf "${BASE}"
  TARGET=`cat "${seedFile}"`
  ./minotari_console_wallet --non-interactive-mode --network Mainnet --base-path "${BASE}" -p base_node.mining_enabled=false -p wallet.grpc_enabled=false --password "${PASSWD}" --recovery --seed-words "${TARGET}"
  [ $? -eq 0 ] && echo -e "\n\n\033[32mNew Wallet Seed\033[0m: \033[31m${TARGET}\033[0m\n\n\n" && exit 0 || exit 1
}

[ "$AMOUNT" == "seed" ] && {
  ./minotari_console_wallet --non-interactive-mode --network Mainnet --base-path "${BASE}" -p base_node.mining_enabled=false -p wallet.grpc_enabled=false --password "${PASSWD}" --recovery --seed-words "${TARGET}"
  exit "$?"
}

[ "$AMOUNT" == "ui" ] && {
  ./minotari_console_wallet --network Mainnet --base-path "${BASE}" -p base_node.mining_enabled=false -p wallet.grpc_enabled=false --password "${PASSWD}"
  exit "$?"
}

result=`./minotari_console_wallet --non-interactive-mode --network Mainnet --base-path "${BASE}" -p base_node.mining_enabled=false -p wallet.grpc_enabled=false --password "${PASSWD}" --command-mode-auto-exit sync 2>/dev/null`
block=`echo "$result" |grep -o '^Completed! Height: [0-9]\+,' |grep -o '[0-9]\+'`
[ -n "$block" ] && [ "$block" -gt "0"  ] && echo "Sync Block Height: ${block}"
echo "$result" |grep '^Available balance:\|^Pending incoming balance:\|^Pending outgoing balance:'
amount=`echo "$result" |grep '^Available balance:' |grep ' T$' |grep -o '[0-9]\+' |head -n1`
[ -n "$amount" ] && [ "$amount" -gt "0" ] || exit 1
[ -n "$AMOUNT" ] || AMOUNT="0"
[ "$AMOUNT" -eq "0" ] && exit 0
[ "$AMOUNT" -gt "0" ] && [ "$AMOUNT" -ge "$amount" ] && AMOUNT="$amount"
[ "$AMOUNT" -eq "-1" ] && AMOUNT="$amount"
[ "$AMOUNT" -le "-2" ] && MINAMOUNT="$((10 ** -AMOUNT))" && [ "$((amount - MINAMOUNT))" -ge "0" ] && AMOUNT="$amount" || exit 0
[ "$AMOUNT" -le "0" ] && exit 1


[ -n "$TARGET" ] || exit 2
[ ! -n "$TARICMD" ] && [ "${#TARGET}" -eq "91" ] && TARICMD="send-minotari"
[ ! -n "$TARICMD" ] && [ "${#TARGET}" -gt "91" ] && TARICMD="send-one-sided-to-stealth-address"
[ -n "$TARICMD" ] || exit 2
result=`./minotari_console_wallet --non-interactive-mode --network Mainnet --base-path "${BASE}" -p base_node.mining_enabled=false -p wallet.grpc_enabled=false --password "${PASSWD}" --command-mode-auto-exit "${TARICMD}" "${AMOUNT}T" "${TARGET}" 2>&1`
TxID=`echo "$result" |grep '^Transaction ID:' |grep -o '[0-9]\+'`
[ -n "$TxID" ] && echo -e "Sending: ${AMOUNT} XTM --> ${TARGET}\nTxID[$(date '+%Y/%m/%d %H:%M:%S')]: ${TxID}\n" && exit 0
exit 1


