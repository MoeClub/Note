# stunnel

## mail.conf
### Yandex
```
IMAP: mail.lib.mk
      993
      SSL

SMTP: mail.lib.mk
      465
      SSL

```

### Larksuit
```
IMAP: mail.lib.mk
      998
      SSL

SMTP: mail.lib.mk
      468
      SSL

```

### Gmail
```
IMAP: mail.lib.mk
      999
      SSL

SMTP: mail.lib.mk
      666
      SSL

SMTP: mail.lib.mk
      667
      STARTTLS

```

### Outlook
```
IMAP: mail.lib.mk
      996
      SSL

SMTP: mail.lib.mk
      581
      STARTTLS

```

### Mail.ru
```
IMAP: mail.lib.mk
      997
      SSL

SMTP: mail.lib.mk
      466
      SSL

```

# Service
```
apt install -y stunnel
wget -qO /etc/stunnel/stunnel.conf https://github.com/MoeClub/Note/raw/master/stunnel/mail.conf
sed -i 's/;[[:space:]]*foreground.*/foreground = yes/' /etc/stunnel/stunnel.conf
wget -qO /etc/stunnel/stunnel.service https://github.com/MoeClub/Note/raw/master/stunnel/stunnel.service
cp -rf /etc/stunnel/stunnel.service /etc/systemd/system/stunnel.service

systemctl daemon-reload
systemctl enable stunnel.service
systemctl start stunnel.service

```

