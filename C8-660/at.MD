```
# 使用 PCIE 模式
sendat 2 'AT+QCFG="pcie/mode",1'
sendat 2 'AT+QCFG="data_interface",1,0'

# 使用 2.5G驱动
sendat 2 'AT+QETH="eth_driver","r8125",1'

# 开机自动拨号
sendat 2 'AT+QMAPWAC=1'

sendat 2 'AT+QMAP="mPDN_rule",0'
sendat 2 'AT+QMAP="mPDN_rule",0,1,0,1,1,"FF:FF:FF:FF:FF:FF"'

```
