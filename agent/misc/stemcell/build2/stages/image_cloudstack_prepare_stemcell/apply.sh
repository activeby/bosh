#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

disk_image_name=root.img
qcow2_image_name=root.qcow2

pushd $work
qemu-img convert -f raw -O qcow2 $disk_image_name $qcow2_image_name
tar zcf stemcell/image $qcow2_image_name
popd
