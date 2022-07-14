#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

import aiosqlite
import asyncio

class SQLite:
    def __init__(self, name, table, loop=None):
        aiosqlite.core.LOG.disabled = True
        self.loop = loop
        self.table = table
        self._path = os.path.join(os.path.dirname(os.path.abspath(__file__)), name)
        self._queue = asyncio.Queue(maxsize=1)
        self._queueInit(queue=self._queue)
        print("Data:", self._path)

    def _queueInit(self, queue):
        try:
            assert queue.maxsize > 0
            for _ in range(queue.maxsize):
                queue.put_nowait(None)
        except:
            pass

    async def _execute(self, sql, write=False):
        value = db = cursor = field = None
        try:
            if write is True:
                await self._queue.get()
                db = await aiosqlite.connect(database=self._path, check_same_thread=False, timeout=60, loop=self.loop)
                cursor = await db.execute(sql)
                await db.commit()
            else:
                db = await aiosqlite.connect(database=self._path, check_same_thread=False, timeout=60, loop=self.loop)
                cursor = await db.execute(sql)
                if cursor.description:
                    field = [i[0] for i in cursor.description]
                records = await cursor.fetchall()
                if field:
                    value = [dict(zip(field, i)) for i in records]
        except Exception as e:
            raise Exception(e)
        finally:
            if cursor is not None:
                await cursor.close()
            if db is not None:
                await db.close()
            if write is True:
                try:
                    self._queue.task_done()
                except:
                    pass
                await self._queue.put(None)
            del field, cursor, db
        return value

    async def Init(self, tbl):
        try:
            vacuum = await self._execute('''PRAGMA auto_vacuum;''')
            if vacuum[0]['auto_vacuum'] == 0:
                await self._execute('''PRAGMA auto_vacuum = 1;''', True)
                await self._execute('''PRAGMA encoding = "UTF-8";''', True)
                # await self._execute('''PRAGMA journal_mode = WAL;''', True)
                await self._execute('''PRAGMA temp_store = MEMORY;''', True)
                await self._execute('''PRAGMA synchronous = NORMAL;''', True)
                # await self._execute('''PRAGMA page_size = 4096;''', True)
                create_tbl = '''create table ''' + self.table + ''' ({})'''.format(tbl)
                await self._execute(create_tbl, True)
        except Exception as e:
            if 'already exists' not in str(e):
                print("init:", e)

                
if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    SQL = SQLite("MoeClub.db", "MoeClub", loop=loop)
    loop.run_until_complete(SQL.Init('row0 text primary key, row1 text, row2 text'))
    loop.run_until_complete(SQL.execute("select * from MoeClub;"))

