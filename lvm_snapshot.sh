#!/bin/sh

# ==============================================================================
#   機能
#     スナップショットリストに記載されたLVMスナップショットを操作する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2010-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_ROOT=`dirname $0`
SCRIPT_NAME=`basename $0`
PID=$$

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数

# プログラム内部変数
FS_MOUNT="/usr/local/sbin/fs_mount.sh"
FS_UMOUNT="/usr/local/sbin/fs_umount.sh"

SNAPSHOT_LIST=""

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
SNAPSHOT_SH="${SCRIPT_TMP_DIR}/snapshot_sh.tmp"
SNAPSHOT_SH_TMP="${SCRIPT_TMP_DIR}/snapshot_sh.tmp.tmp"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    lvm_snapshot.sh [OPTIONS ...] MODE SNAPSHOT_LIST
		
		    MODE : {create|remove|mount|umount|info}
		    SNAPSHOT_LIST : Specify the snapshot filesystem list.
		
		OPTIONS:
		    --help
		       Display this help and exit.
	EOF
}

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o \"\" -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing MODE argument" 1>&2
	USAGE;exit 1
else
	# モードのチェック
	case "$1" in
	create|remove|mount|umount|info)
		MODE="$1"
		;;
	*)
		echo "-E Invalid MODE argument" 1>&2
		USAGE;exit 1
		;;
	esac
fi

# 第2引数のチェック
if [ "$2" = "" ];then
	echo "-E Missing SNAPSHOT_LIST argument" 1>&2
	USAGE;exit 1
else
	SNAPSHOT_LIST="$2"
	# スナップショットリストのチェック
	if [ ! -f "${SNAPSHOT_LIST}" ];then
		echo "-E SNAPSHOT_LIST not a file -- \"${SNAPSHOT_LIST}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 作業開始前処理
PRE_PROCESS

# 作業用 スナップショットスクリプトのヘッダ作成
echo "#!/bin/sh" >  "${SNAPSHOT_SH}"
echo             >> "${SNAPSHOT_SH}"
chmod 0755          "${SNAPSHOT_SH}"

# 作業用 スナップショットスクリプトの作成
while read line ; do
	# コメントと空行は無視
	echo "${line}" | grep -q -e '^#' -e '^$'
	if [ $? -ne 0 ];then
		# 第1フィールド(必須)の取得
		src_lv_path="`echo \"${line}\" | awk -F '\t' '{print $1}'`"
		# 第2フィールド(必須)の取得
		dest_pv_path="`echo \"${line}\" | awk -F '\t' '{print $2}'`"
		# 第3フィールド(必須)の取得
		snap_lv_path="`echo \"${line}\" | awk -F '\t' '{print $3}'`"
		# 第4フィールド(必須)の取得
		snap_le_number="`echo \"${line}\" | awk -F '\t' '{print $4}'`"
		# 第5フィールドの取得
		snap_chunksize="`echo \"${line}\" | awk -F '\t' '{print $5}'`"
		# 第6フィールドの取得
		snap_permission="`echo \"${line}\" | awk -F '\t' '{print $6}'`"
		# 第7フィールド(必須)の取得
		mnt_dir="`echo \"${line}\" | awk -F '\t' '{print $7}'`"
		# 第8フィールドの取得
		mnt_opt="`echo \"${line}\" | awk -F '\t' '{print $8}'`"
		# 必須フィールドのチェック
		if [ "${src_lv_path}" = "" -o "${dest_pv_path}" = "" -o "${snap_lv_path}" = "" -o "${snap_le_number}" = "" -o "${mnt_dir}" = "" ];then
			echo "-E Invalid SNAPSHOT_LIST format -- \"${SNAPSHOT_LIST}\"" 1>&2
			echo "${line}"
			POST_PROCESS;exit 1
		fi
		# スナップショット元論理ボリューム名の取得
		src_lv_name="`LANG=C lvdisplay ${src_lv_path} | sed -n 's#^.*LV Name *\(.*\)$#\1#p'`"
		# スナップショット元ボリュームグループ名の取得
		src_vg_name="`LANG=C lvdisplay ${src_lv_path} | sed -n 's#^.*VG Name *\(.*\)$#\1#p'`"
		# スナップショット論理ボリューム名の取得
		snap_lv_name="`basename ${snap_lv_path} | sed \"s#^${src_vg_name}-##\"`"
		# コマンドラインの構成
		case "${MODE}" in
		create)
			echo "lvcreate -s -l ${snap_le_number} ${snap_chunksize:+-c ${snap_chunksize}} ${snap_permission:+-p ${snap_permission}} -n ${snap_lv_name} ${src_vg_name}/${src_lv_name} ${dest_pv_path}"
			;;
		remove)
			echo "lvremove -f ${snap_lv_path}"
			;;
		mount)
			echo "${FS_MOUNT} local \"${snap_lv_path}\" \"${mnt_dir}\" ${mnt_opt}"
			;;
		umount)
			echo "${FS_UMOUNT} local \"${snap_lv_path}\" \"${mnt_dir}\""
			;;
		info)
			echo "echo"
			echo "echo \"##############################################################################\""
			echo "echo \"# lvdisplay --maps ${snap_lv_path}\""
			echo "echo \"##############################################################################\""
			echo "lvdisplay --maps ${snap_lv_path}"
			;;
		esac
	fi
done < "${SNAPSHOT_LIST}" > "${SNAPSHOT_SH_TMP}"

case ${MODE} in
# モードがumountの場合
umount)
	# 作業用 スナップショットスクリプトの各行の記載順を逆転
	tac "${SNAPSHOT_SH_TMP}" >> "${SNAPSHOT_SH}"
	;;
# モードがumount以外の場合
*)
	# 作業用 スナップショットスクリプトの各行の記載順を維持
	cat "${SNAPSHOT_SH_TMP}" >> "${SNAPSHOT_SH}"
	;;
esac
rm -f "${SNAPSHOT_SH_TMP}"

# 処理開始メッセージの表示
echo
echo "-I Snapshot ${MODE} has started."

#####################
# メインループ 開始 #
#####################

if [ ${DEBUG} ];then
	cat "${SNAPSHOT_SH}"
	echo
fi
"${SNAPSHOT_SH}"
SNAPSHOT_SH_RC=$?

#####################
# メインループ 終了 #
#####################

# 処理終了メッセージの表示
if [ ${SNAPSHOT_SH_RC} -ne 0 ];then
	echo
	echo "-E Snapshot ${MODE} has ended unsuccessfully." 1>&2
	POST_PROCESS;exit ${SNAPSHOT_SH_RC}
else
	echo
	echo "-I Snapshot ${MODE} has ended successfully."
	# 作業終了後処理
	POST_PROCESS;exit 0
fi

