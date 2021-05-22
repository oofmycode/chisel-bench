#!/bin/sh
# exercise tail -c

# Copyright 2014-2021 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
print_ver_ tail

# Make sure it works on funny files in /proc and /sys.
for file in /proc/version /sys/kernel/profiling; do
  if test -r $file; then
    cp -f $file copy &&
    tail -c -1 copy > exp || framework_failure_

    tail -c -1 $file > out || fail=1
    compare exp out || fail=1
  fi
done

# Make sure it works for pipes
printf '123456' | tail -c3 > out || fail=1
printf '456' > exp || framework_failure_
compare exp out || fail=1

Exit $fail
