# Copyright 2022 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Create a repository to hold the toolchains.

This follows guidance here:
https://docs.bazel.build/versions/main/skylark/deploying.html#registering-toolchains

The "complex computation" in our case is simply downloading large artifacts.
This guidance tells us how to avoid that: we put the toolchain targets in the
alias repository with only the toolchain attribute pointing into the
platform-specific repositories.
"""

PLATFORMS = {
    "aarch64-apple-darwin": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:aarch64",
        ],
    ),
    "x86_64-apple-darwin": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "x86_64-unknown-linux-gnu": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
}

def _toolchains_repo_impl(repository_ctx):
    build_content = """\
# Generated by toolchains_repo.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains
# flag. By default all these toolchains are registered by the
# python_register_toolchains macro so you don't normally need to interact with
# these targets.

"""

    for [platform, meta] in PLATFORMS.items():
        build_content += """\
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    target_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:python_runtimes",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)
""".format(
            platform = platform,
            name = repository_ctx.attr.name,
            user_repository_name = repository_ctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    repository_ctx.file("BUILD.bazel", build_content)

toolchains_repo = repository_rule(
    _toolchains_repo_impl,
    doc = "Creates a repository with toolchain definitions for all known platforms " +
          "which can be registered or selected.",
    attrs = {
        "user_repository_name": attr.string(doc = "what the user chose for the base name"),
    },
)