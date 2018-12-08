#!/usr/bin/env python3
# Copyright (c) 2018-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

import contextlib
import io
import pathlib
import typing


_BinaryIO = typing.Union[typing.IO[bytes], io.BufferedIOBase]


@contextlib.contextmanager
def forward_log_file(
    file_path: pathlib.Path, output_file: _BinaryIO
) -> typing.Iterator["LogForwarder"]:
    with follow_log_file(file_path) as follower:
        yield LogForwarder(follower=follower, output_file=output_file)


class LogForwarder:
    __follower: "LogFollower"
    __output_file: _BinaryIO

    def __init__(self, follower: "LogFollower", output_file: _BinaryIO) -> None:
        super().__init__()
        self.__follower = follower
        self.__output_file = output_file

    def poll(self) -> None:
        self.__output_file.write(self.__follower.poll())
        self.__output_file.flush()


@contextlib.contextmanager
def follow_log_file(file_path: pathlib.Path) -> typing.Iterator["LogFollower"]:
    with open(file_path, "rb") as file:
        yield LogFollower(file)


class LogFollower:
    __file: _BinaryIO

    def __init__(self, file: _BinaryIO) -> None:
        super().__init__()
        self.__file = file

    def poll(self) -> bytes:
        return self.__file.read()