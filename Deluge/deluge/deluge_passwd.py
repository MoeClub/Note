#!/usr/bin/env python                                                                                                                                                                         
# Changes the password for Deluge's Web UI

from deluge.config import Config
from functools import reduce
import hashlib
import os.path
import sys

def make_checksum(session_id):
    return reduce(lambda x,y:x+y, map(ord, session_id))

if len(sys.argv) == 1 or len(sys.argv) == 2:
    #deluge_dir = os.path.expanduser(sys.argv[1])
    deluge_dir = os.path.dirname(os.path.abspath(__file__))

    if os.path.isdir(deluge_dir):
        try:
            config = Config("web.conf", config_dir=deluge_dir)
        except IOError, e:
            print "Can't open web ui config file: ", e
        else:
            if len(sys.argv) == 1:
                password = raw_input("Enter new password: ")
            else:
                password = str(sys.argv[1])
            s = hashlib.sha1()
            s.update(config['pwd_salt'])
            s.update(password)
            config['pwd_sha1'] = s.hexdigest()
            m = hashlib.md5()
            m.update(config['pwd_salt'])
            m.update(password)
            sessions_id = str(m.hexdigest())
            config['sessions'] = {}
            config['sessions'][sessions_id] = {"login": "admin", "expires": 4102376400.0, "level": 10}
            config['session_timeout'] = 31536000
            try:
                sessions_sum = str(make_checksum(sessions_id))
                config.save()
            except IOError, e:
                print "Couldn't save new config: ", e
            else:
                print '''_session_id: "''' + sessions_id + sessions_sum + '''"'''
                print "New config successfully set!"
    else:
        print "%s is not a directory!" % deluge_dir
else:
    print "Usage: %s [new password]" % (os.path.basename(sys.argv[0]))

