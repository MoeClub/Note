#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author:  MoeClub.org

# pip3 install pyrogram tgcrypto aiohttp

import os
import math
import asyncio
from aiohttp import web
from typing import Union
from pyrogram import Client, raw
from pyrogram.session import Session, Auth
from pyrogram import file_id


class TGSteamer:
    # https://my.telegram.org/              # apiId, apiHash
    # https://telegram.me/BotFather         # botToken

    cacheFileId = {}
    lock = asyncio.Lock()

    @classmethod
    async def chunk_size(cls, length):
        return 2 ** max(min(math.ceil(math.log2(length / 1024)), 10), 2) * 1024

    @classmethod
    async def offset_fix(cls, offset, chunkSize):
        offset -= offset % chunkSize
        return offset

    @classmethod
    async def get_client(cls, apiId, apiHash, botToken, appName=os.path.basename(os.path.abspath(__file__)).split(".")[0]):
        _client = Client(
            name=appName,
            api_id=int(str(apiId).strip()),
            api_hash=str(apiHash).strip(),
            bot_token=str(botToken).strip(),
            in_memory=True,
        )
        await _client.start()
        assert _client.is_connected and _client.is_initialized
        return _client

    @classmethod
    async def get_file_properties(cls, fileId):
        async with cls.lock:
            fileProperties = cls.cacheFileId.get(fileId, None)
            if fileProperties is None:
                fileProperties = file_id.FileId.decode(fileId)
                setattr(fileProperties, "file_size", getattr(fileProperties, "file_size", 0))
                setattr(fileProperties, "file_name", getattr(fileProperties, "file_name", ""))
                cls.cacheFileId[fileId] = fileProperties
        return fileProperties

    @classmethod
    async def get_session(cls, client: Client, data: file_id.FileId):
        async with client.media_sessions_lock:
            session = client.media_sessions.get(data.dc_id, None)

            if session is None:
                test_mode = await client.storage.test_mode()
                dc_id = await client.storage.dc_id()
                if data.dc_id != dc_id:
                    auth = await Auth(client, data.dc_id, test_mode).create()
                else:
                    auth = await client.storage.auth_key()

                session = Session(client, data.dc_id, auth, test_mode, is_media=True, is_cdn=False)

                try:
                    await session.start()
                    if data.dc_id != dc_id:
                        exported = await client.invoke(raw.functions.auth.ExportAuthorization(dc_id=data.dc_id))
                        await session.invoke(raw.functions.auth.ImportAuthorization(id=exported.id, bytes=exported.bytes))
                    client.media_sessions[data.dc_id] = session
                except Exception as e:
                    session = None

        return session

    @classmethod
    async def get_location(cls, data: file_id.FileId):
        file_type = data.file_type

        if file_type == file_id.FileType.PHOTO:
            location = raw.types.InputPhotoFileLocation(
                id=data.media_id,
                access_hash=data.access_hash,
                file_reference=data.file_reference,
                thumb_size=data.thumbnail_size
            )
        else:
            location = raw.types.InputDocumentFileLocation(
                id=data.media_id,
                access_hash=data.access_hash,
                file_reference=data.file_reference,
                thumb_size=data.thumbnail_size
            )

        return location

    @classmethod
    async def yield_bytes(cls, client: Client, fileId: file_id.FileId, offset: int, chunkSize: int) -> Union[str, None]:
        data = cls.get_file_properties(fileId) if isinstance(fileId, str) else fileId
        location = await cls.get_location(data)
        session = await cls.get_session(client, data)

        if session is None:
            raise Exception("InvalidSession")

        r = await session.send(
            raw.functions.upload.GetFile(
                location=location,
                offset=offset,
                limit=chunkSize
            ),
        )

        if isinstance(r, raw.types.upload.File):
            while True:
                chunk = r.bytes
                if not chunk:
                    break

                offset += chunkSize
                yield chunk

                r = await session.send(
                    raw.functions.upload.GetFile(
                        location=location,
                        offset=offset,
                        limit=chunkSize
                    ),
                )

    @classmethod
    async def download_as_bytesio(cls, client, fileId, chunkSize=1024 * 1024):
        data = cls.get_file_properties(fileId) if isinstance(fileId, str) else fileId
        location = await cls.get_location(data)
        session = await cls.get_session(client, data)

        if session is None:
            raise Exception("InvalidSession")

        offset = 0

        r = await session.send(
            raw.functions.upload.GetFile(
                location=location,
                offset=offset,
                limit=chunkSize
            )
        )

        Bytes = []
        if isinstance(r, raw.types.upload.File):
            while True:
                chunk = r.bytes

                if not chunk:
                    break

                Bytes += chunk

                offset += chunkSize

                r = await session.send(
                    raw.functions.upload.GetFile(
                        location=location,
                        offset=offset,
                        limit=chunkSize
                    )
                )

        return Bytes


class Web:
    TelegramFile = TGSteamer()
    TelegramFileClient = None
    Index = "TelegramFile"

    @classmethod
    def Headers(cls, **kwargs):
        headers = {
            "Server": "TelegramFile"
        }
        for item in kwargs:
            headers[item] = kwargs[item]
        return headers

    @classmethod
    async def fileHandler(cls, request: web.Request):
        try:
            _fileId = str(request.match_info["fileId"]).strip("/")
            assert len(_fileId) > 0
            try:
                fileId = await cls.TelegramFile.get_file_properties(_fileId)
            except Exception as e:
                raise Exception("Invalid FileId")
            return await cls.streamer(request=request, fileId=fileId)
        except Exception as e:
            return web.Response(text=str(e).strip(), status=404, headers={"Server": cls.Index}, content_type="text/plain")

    @classmethod
    async def streamer(cls, request: web.Request, fileId: file_id.FileId):
        range_header = request.headers.get("Range", 0)
        file_size = fileId.file_size
        rangeSupport = True if file_size > 0 else False
        file_name = str(fileId.media_id).strip() if fileId.file_name == "" else str(fileId.file_name).strip()

        headers = {
            "Content-Type": "application/octet-stream",
            "Content-Disposition": f'attachment; filename="{file_name}"',
            "Server": cls.Index,
        }

        try:
            assert range_header and rangeSupport
            from_bytes, until_bytes = range_header.replace("bytes=", "").split("-")
            from_bytes = int(from_bytes) if int(from_bytes) >= 0 else 0
            until_bytes = int(until_bytes) if until_bytes and int(until_bytes) > from_bytes else file_size - 1
            req_length = until_bytes - from_bytes + 1
            headers["Accept-Ranges"] = "bytes"
            headers["Content-Length"] = str(req_length),
            headers["Content-Range"] = f"bytes {from_bytes}-{until_bytes}/{file_size}"
        except:
            from_bytes = 0

        chunk_size = 1024 * 1024 if file_size <= 0 else cls.TelegramFile.chunk_size(file_size)
        offset = from_bytes - (from_bytes % chunk_size)

        body = cls.TelegramFile.yield_bytes(cls.TelegramFileClient, fileId, offset, chunk_size)
        code = 206 if rangeSupport else 200

        return web.Response(status=code, body=body, headers=headers)


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    Web.TelegramFileClient = loop.run_until_complete(Web.TelegramFile.get_client(
        int("appId"),
        str("appHash"),
        str("botToken")
    ))
    app = web.Application()
    app.add_routes([web.get(path=str("/{}").format(str(Web.Index).strip("/")) + '{fileId:/[-_\w]+}', handler=Web.fileHandler, allow_head=False)])

    logging_format = '%t %a %s %r [%Tfs]'
    web.run_app(app=app, host="0.0.0.0", port=63838, access_log_format=logging_format, loop=loop)

