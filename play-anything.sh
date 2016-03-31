#!/bin/sh -e

###
# This file is part of "./play.it Archlinux Edition".
# "./play.it Archlinux Edition" is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# "./play.it Archlinux Edition" is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with "./play.it Archlinux Edition".  If not, see <http://www.gnu.org/licenses/>. 2
###

###
# common functions for ./play.it scripts
#
# library version 1.13.15
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

checksum() {
local file="$1"
local options="$2"
shift 2
parse_options "${options}"
printf '%s %s…\n' "$(l10n 'checksum')" "${file##*/}"
if [ "${opts_quiet}" = '0' ]; then print wait; fi
file_md5="$(md5sum "${file}" | cut -d' ' -f1)"
case $# in
	1)
		if [ "${file_md5}" != "$1" ]; then
			checksum_error "${file}"
		fi
	;;
	2)
		if [ "${file_md5}" != "$1" ] && [ "${file_md5}" != "$2" ]; then
			checksum_error "${file}"
		fi
	;;
esac
if [ "${opts_quiet}" = '0' ]; then print done; fi
}

extract_data() {
local type="$1"
local archive="$2"
local target="$3"
local options="$4"
local password="$5"
parse_options "${options}"
printf '%s %s…\n' "$(l10n 'extract_data')" "${archive##*/}"
if [ "${opts_quiet}" = '0' ]; then print wait ; fi
mkdir -p "${target}"
if [ "${type}" = '7z' ]; then
	extract_7z "${archive}" "${target}"
elif [ "${type}" = 'inno' ]; then
	innoextract -seL -p1 -d "${target}" "${archive}"
elif [ "${type}" = 'mojo' ] && [ "${opts_force}" = '1' ]; then
	unzip -qq -o -d "${target}" "${archive}" 2>/dev/null || true
elif [ "${type}" = 'mojo' ]; then
	unzip -qq -d "${target}" "${archive}" 2>/dev/null || true
elif [ "${type}" = 'tar' ]; then
	tar xf "${archive}" -C "${target}"
elif [ "${type}" = 'unar_passwd' ]; then
	unar -q -o "${target}" -D -p "${password}" "${archive}" >/dev/null
elif [ "${type}" = 'zip' ] && [ "${opts_force}" = '1' ]; then
	unzip -qq -o -d "${target}" "${archive}" 2>/dev/null
elif [ "${type}" = 'zip' ]; then
	unzip -qq -d "${target}" "${archive}" 2>/dev/null
elif [ -n "${type}" ]; then
	print error
	printf '%s: %s.\n' "${type}" "$(l10n 'extract_data_unknown_type')"
	exit 1
else
	print error
	printf '%s' "$(l10n 'extract_data_no_type')"
	exit 1
fi
if [ "${opts_tolower}" = '1' ]; then tolower "${target}"; fi
if [ "${opts_fix_rights}" = '1' ]; then fix_rights "${target}"; fi
if [ "${opts_quiet}" = '0' ]; then print done ; fi
}

extract_icons() {
local id="$1"
local icon="$2"
local icon_res="$3"
local target="$4"
local extra_infos="$5"
if [ -n "${extra_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'extract_icons')" "${icon##*/}" "${extra_infos}"
else
	printf '%s %s…\n' "$(l10n 'extract_icons')" "${icon##*/}"
fi
if [ "${icon##*.}" = 'exe' ]; then
	wrestool -o "${target}" -t 14 -x "${PKG1_DIR}${PATH_GAME}/${icon}"
	icotool -o "${target}" -x "$(realpath "${target}"/*.ico | head -n1)" 2>/dev/null
	rm "${target}"/*.ico
elif [ "${icon##*.}" = 'ico' ]; then
	icotool -o "${target}" -x "${PKG1_DIR}${PATH_GAME}/${icon}" 2>/dev/null
elif [ "${icon##*.}" = 'bmp' ]; then
	convert "${PKG1_DIR}${PATH_GAME}/${icon}" "${target}/${id}.png"
else
	print error
	printf '%s.\n\n' "$(l10n 'extract_icons_error')"
	exit 1
fi
if [ "${icon##*.}" = 'exe' ] || [ "${icon##*.}" = 'ico' ] ; then
	for res in ${icon_res}; do
		path="${PATH_ICON_BASE}/${res}/apps"
		mkdir -p "${PKG1_DIR}${path}"
		for file in "${target}"/*${res}x*.png; do
			mv "${file}" "${PKG1_DIR}${path}/${id}.png"
		done
	done
fi
}

fetch_args() {
export GAME_ARCHIVE=''
export GAME_ARCHIVE_CHECKSUM=''
export GAME_LANG=''
export GAME_LANG_TXT=''
export GAME_LANG_VOICES=''
export PKG_COMPRESSION=''
export PKG_PREFIX=''
export WITH_MOVIES=''
for arg in "$@"; do
	case "${arg}" in
		'--help'*)
			help
			exit 0
		;;
		'--checksum='*)
			export GAME_ARCHIVE_CHECKSUM="${arg#*=}"
		;;
		'--compression='*)
			export PKG_COMPRESSION="${arg#*=}"
		;;
		'--lang='*)
			if [ -n "${GAME_LANG_DEFAULT}" ]; then
				GAME_LANG="${arg#*=}"
			else
				print warning
				printf '%s: %s.\n%s.\n' "${arg%%=*}" "$(l10n 'option_unsupported')" "$(l10n 'option_ignored')"
			fi
		;;
		'--lang-txt='*)
			if [ -n "${GAME_LANG_TXT_DEFAULT}" ]; then
				GAME_LANG_TXT="${arg#*=}"
			else
				print warning
				printf '%s: %s.\n%s.\n' "${arg%%=*}" "$(l10n 'option_unsupported')" "$(l10n 'option_ignored')"
			fi
		;;
		'--lang-voices='*)
			if [ -n "${GAME_LANG_VOICES_DEFAULT}" ]; then
				GAME_LANG_VOICES="${arg#*=}"
			else
				print warning
				printf '%s: %s.\n%s.\n' "${arg%%=*}" "$(l10n 'option_unsupported')" "$(l10n 'option_ignored')"
			fi
		;;
		'--prefix='*)
			export PKG_PREFIX="${arg#*=}"
		;;
		'--with-movies')
			if [ -n "${WITH_MOVIES_DEFAULT}" ]; then
				WITH_MOVIES='1'
			else
				print warning
				printf '%s: %s.\n%s.\n' "${arg%%=*}" "$(l10n 'option_unsupported')" "$(l10n 'option_ignored')"
			fi
		;;
		'--'*)
			print warning
			printf '%s: %s.\n%s.\n' "${arg%%=*}" "$(l10n 'option_unknown')" "$(l10n 'option_ignored')"
		;;
		*)
			export GAME_ARCHIVE="${arg}"
		;;
	esac
done
}

fix_rights() {
local targets="$*"
printf '%s…\n' "$(l10n 'fix_rights')"
for target in ${targets}; do
	find "${target}" -type d -exec chmod 755 '{}' +
	find "${target}" -type f -exec chmod 644 '{}' +
done
}

game_mkdir() {
local dir_var="$1"
local dir_name="$2"
local size_limit="$3"
if [ $(df --output=avail /tmp | tail -n1) -ge ${size_limit} ]; then
	export ${dir_var}="/tmp/${dir_name}"
else
	export ${dir_var}="${PWD}/${dir_name}"
fi
}

help() {
	printf '%s %s' "$0" '[<archive>] [--checksum=md5|none] [--compression=none|gzip|xz] [--prefix=dir]'
	if [ -n "${GAME_LANG_DEFAULT}" ]; then
		printf ' [--lang=en|fr]'
	fi
	if [ -n "${WITH_MOVIES_DEFAULT}" ]; then
		printf ' [--with-movies]'
	fi
	printf '\n\n'
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--checksum=md5|none' "$(l10n 'help_checksum')" "$(l10n 'help_default')" "${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--compression=none|gzip|xz' "$(l10n 'help_compression')" "$(l10n 'help_default')" "${PKG_COMPRESSION_DEFAULT}"
	printf '\t%s\n\t%s.\n\t(%s: %s)\n\n' '--prefix=DIR' "$(l10n 'help_prefix')" "$(l10n 'help_default')" "${PKG_PREFIX_DEFAULT}"
	if [ -n "${GAME_LANG_DEFAULT}" ]; then
		printf '\t%s\n\t%s.\n\t%s\n\t%s\n\t(%s: %s)\n\n' '--lang=en|fr' "$(l10n 'help_lang')" "$(l10n 'help_lang_en')" "$(l10n 'help_lang_fr')" "$(l10n 'help_default')" "${GAME_LANG_DEFAULT}"
	fi
	if [ -n "${WITH_MOVIES_DEFAULT}" ]; then
		printf '\t%s\n\t%s.\n\t(%s)\n\n' '--with-movies' "$(l10n 'help_movies')" "$(l10n 'help_movies_default')"
	fi
}

l10n() {
local keyword="$1"
local lang="${LANG%_*}"
case "${lang}" in
	fr|en)
		printf '%s' "${STRINGS_BANK}" | grep "^${keyword}:${lang}:" | cut -d ':' -f3-
	;;
	*)
		printf '%s' "${STRINGS_BANK}" | grep "^${keyword}:en:" | cut -d ':' -f3-
	;;
esac
}

parse_options() {
for option in 'fix_rights' 'force' 'quiet' 'terminal' 'tolower'; do
	if [ -n "$(printf '%s' "$*" | grep "${option}")" ]; then
		export opts_${option}='1'
	else
		export opts_${option}='0'
	fi
done
}

print() {
case $1 in
	done)
		string_format='\033[0;32m%s\033[0m\n\n'
		string_contents="$(l10n 'print_done')"
	;;
	error)
		string_format='\n\033[1;31m%s\033[0m\n'
		string_contents="$(l10n 'print_error')"
	;;
	wait)
		string_format='%s\n'
		string_contents="$(l10n 'print_wait')"
	;;
	warning)
		string_format='\n\033[1;33m%s\033[0m\n'
		string_contents="$(l10n 'print_warning')"
	;;
esac
printf "${string_format}" "${string_contents}"
}

print_instructions() {
local desc="$1"
shift 1
printf '%s %s %s:\ndpkg -i' "$(l10n 'install_instructions_1')" "$(printf '%s' "${desc}" | head -n1)" "$(l10n 'install_instructions_2')"
while [ -n "$1" ]; do
	printf ' %s' "${PWD}/${1##*/}.deb"
	shift 1
done
printf '\napt-get install -f\n'
}

set_checksum() {
if [ -z "${GAME_ARCHIVE_CHECKSUM}" ]; then export GAME_ARCHIVE_CHECKSUM="${GAME_ARCHIVE_CHECKSUM_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_checksum')" "${GAME_ARCHIVE_CHECKSUM}"
if [ -z "$(printf '#md5sum#none#' | grep "#${GAME_ARCHIVE_CHECKSUM}#")" ]; then
	print error
	printf '%s %s --checksum.\n' "${GAME_ARCHIVE_CHECKSUM}" "$(l10n 'value_invalid')"
	printf '%s: none, md5sum\n' "$(l10n 'value_accepted')"
	printf '%s: %s\n\n' "$(l10n 'value_default')" "${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
	exit 1
fi
}

set_compression() {
if [ -z "${PKG_COMPRESSION}" ]; then export PKG_COMPRESSION="${PKG_COMPRESSION_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_compression')" "${PKG_COMPRESSION}"
if [ -z "$(printf '#gzip#xz#none#' | grep "#${PKG_COMPRESSION}#")" ]; then
	print error
	printf '%s %s --compression.\n' "${PKG_COMPRESSION}" "$(l10n 'value_invalid')"
	printf '%s: none, gzip, xz\n' "$(l10n 'value_accepted')"
	printf '%s: %s\n\n' "$(l10n 'value_default')" "${PKG_COMPRESSION_DEFAULT}"
	exit 1
fi
}

set_lang() {
if [ -z "${GAME_LANG}" ]; then export GAME_LANG="${GAME_LANG_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_lang')" "${GAME_LANG}"
if [ -z "$(printf '#en#fr#' | grep "#${GAME_LANG}#")" ]; then
	print error
	printf '%s %s --lang.\n' "${GAME_LANG}" "$(l10n 'value_invalid')"
	printf '%s: en, fr\n' "$(l10n 'value_accepted')"
	printf '%s: %s\n' "$(l10n 'value_default')" "${GAME_LANG_DEFAULT}"
	printf '\n'
	exit 1
fi
}

set_prefix() {
if [ -z "${PKG_PREFIX}" ]; then export PKG_PREFIX="${PKG_PREFIX_DEFAULT}"; fi
printf '%s: %s\n' "$(l10n 'set_prefix')" "${PKG_PREFIX}"
if [ "$(printf '%s' "${PKG_PREFIX}" | cut -c1)" != '/' ]; then
	print error
	printf '%s.\n' "$(l10n 'set_prefix_error')"
	printf '%s: %s\n\n' "$(l10n 'value_default')" "${PKG_PREFIX_DEFAULT}"
	exit 1
fi
}

set_target() {
local archives_nb="$1"
local origin="$2"
printf '%s…\n' "$(l10n 'set_target')"
if [ -z "${GAME_ARCHIVE}" ]; then
	if [ -f "${PWD}/${GAME_ARCHIVE1}" ]; then
		export GAME_ARCHIVE="${PWD}/${GAME_ARCHIVE1}"
	elif [ -f "${HOME}/${GAME_ARCHIVE1}" ]; then
		export GAME_ARCHIVE="${HOME}/${GAME_ARCHIVE1}"
	elif [ ${archives_nb} -ge 2 ] && [ -f "${PWD}/${GAME_ARCHIVE2}" ]; then
		export GAME_ARCHIVE="${PWD}/${GAME_ARCHIVE2}"
	elif [ ${archives_nb} -ge 2 ] && [ -f "${HOME}/${GAME_ARCHIVE2}" ]; then
		export GAME_ARCHIVE="${HOME}/${GAME_ARCHIVE2}"
	else
		print error
		printf '%s %s. (%s' "$(l10n 'set_target_missing')" "${origin}" "${GAME_ARCHIVE1}"
		if [ ${archives_nb} -ge 2 ]; then printf ', %s' "${GAME_ARCHIVE2}"; fi
		printf ')\n\n'
		exit 1
	fi
fi
printf '%s %s\n' "$(l10n 'using')" "${GAME_ARCHIVE}"
if ! [ -f "${GAME_ARCHIVE}" ]; then
	print error
	printf '%s %s.\n\n' "${GAME_ARCHIVE}" "$(l10n 'not_found')"
	exit 1
fi
}

set_target_extra() {
local varname="$1"
local url="$2"
shift 2
local archive1="$1"
if [ $# -ge 2 ]; then
	local archive2="$2";
fi
if [ $# -ge 3 ]; then
	local archive3="$3";
fi
if [ -e "${GAME_ARCHIVE%/*}/${archive1}" ]; then
	archive="${GAME_ARCHIVE%/*}/${archive1}"
	export ${varname}="${archive}"
elif [ $# -ge 2 ] && [ -e "${GAME_ARCHIVE%/*}/${archive2}" ]; then
	archive="${GAME_ARCHIVE%/*}/${archive2}"
	export ${varname}="${archive}"
elif [ $# -ge 3 ] && [ -e "${GAME_ARCHIVE%/*}/${archive3}" ]; then
	archive="${GAME_ARCHIVE%/*}/${archive3}"
	export ${varname}="${archive}"
else
	print error
	printf '%s' "${archive1}"
	if [ $# -ge 2 ]; then
		printf ', %s' "${archive2}";
	fi
	if [ $# -ge 3 ]; then
		printf ', %s' "${archive3}";
	fi
	if [ $# = 1 ]; then
		printf ' %s.\n%s %s.\n' "$(l10n 'not_found')" "$(l10n 'set_target_extra_missing')" "${GAME_ARCHIVE}"
		if [ -n "${url}" ]; then
			printf '%s:\n%s\n\n' "$(l10n 'set_target_extra_missing_url')" "${url}"
		fi
	else
		printf ' %s.\n%s %s.\n' "$(l10n 'not_found_multiple')" "$(l10n 'set_target_extra_missing_multiple')" "${GAME_ARCHIVE}"
		if [ -n "${url}" ]; then
			printf '%s:\n%s\n\n' "$(l10n 'set_target_extra_missing_multiple_url')" "${url}"
		fi
	fi
	exit 1
fi
printf '%s %s\n' "$(l10n 'using' )" "${archive}"
}

set_target_optional() {
local varname="$1"
shift 1
for archive in "$@"; do
	if [ -e "${GAME_ARCHIVE%/*}/${archive}" ]; then
		archive="${GAME_ARCHIVE%/*}/${archive}"
		export ${varname}="${archive}"
		printf '%s %s\n' "$(l10n 'using' )" "${archive}"
		break
	else
		export ${varname}=''
	fi
done
}

set_workdirs() {
local pkg_nb="$1"
if [ -z "${GAME_ID_SHORT}" ]; then
	export GAME_ID_SHORT="${GAME_ID}"
fi
if [ -z "${GAME_ARCHIVE_FULLSIZE}" ]; then
	export GAME_ARCHIVE_FULLSIZE="${GAME_FULL_SIZE}"
fi
game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
if [ ${pkg_nb} -ge 2 ]; then
	game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fi
}

tolower() {
local target="$1"
printf '%s…\n' "$(l10n 'tolower')"
find "${target}" -depth | while read file; do
	newfile="${file%/*}/$(printf '%s' "${file##*/}" | tr [:upper:] [:lower:])"
	if [ "${newfile}" != "${file}" ] && [ "${file}" != "${target}" ]; then
		mv "${file}" "${newfile}"
	fi
done
}

write_bin_dosbox() {
local target="$1"
local exe="$2"
local exe_options="$3"
local more_infos="$4"
shift 4
if [ -n "$1" ]; then
	local exe_description="$1"
else
	local exe_description="${exe##*/}"
fi
if [ -n "${more_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_bin')" "${exe_description}" "${more_infos}"
else
	printf '%s %s…\n' "$(l10n 'write_bin')" "${exe_description}"
fi
cat > "${target}" << EOF
#!/bin/sh -e

# Import essential functions
. "${PATH_BIN}/${APP_COMMON_ID}"

# Setting game-specific variables
GAME_ID="${GAME_ID}"
GAME_EXE="${exe}"
GAME_IMAGE="${GAME_IMAGE}"
GAME_PATH="${PATH_GAME}"
GAME_CACHE_DIRS="${GAME_CACHE_DIRS}"
GAME_CACHE_FILES="${GAME_CACHE_FILES}"
GAME_CACHE_FILES_POST="${GAME_CACHE_FILES_POST}"
GAME_CONFIG_DIRS="${GAME_CONFIG_DIRS}"
GAME_CONFIG_FILES="${GAME_CONFIG_FILES}"
GAME_CONFIG_FILES_POST="${GAME_CONFIG_FILES_POST}"
GAME_DATA_DIRS="${GAME_DATA_DIRS}"
GAME_DATA_FILES="${GAME_DATA_FILES}"
GAME_DATA_FILES_POST="${GAME_DATA_FILES_POST}"

# Setting prefix-specific variables
if [ -n "\${XDG_CACHE_HOME}" ]; then
	USERDIR_CACHE="\${XDG_CACHE_HOME}/\${GAME_ID}"
else
	USERDIR_CACHE="\${HOME}/.cache/\${GAME_ID}"
fi
if [ -n "\${XDG_CONFIG_HOME}" ]; then
	USERDIR_CONFIG="\${XDG_CONFIG_HOME}/\${GAME_ID}"
else
	USERDIR_CONFIG="\${HOME}/.config/\${GAME_ID}"
fi
if [ -n "\${XDG_DATA_HOME}" ]; then
	USERDIR_DATA="\${XDG_DATA_HOME}/games/\${GAME_ID}"
	DOSPREFIX="\${XDG_DATA_HOME}/dosbox/prefixes/\${GAME_ID}"
else
	USERDIR_DATA="\${HOME}/.local/share/games/\${GAME_ID}"
	DOSPREFIX="\${HOME}/.local/share/dosbox/prefixes/\${GAME_ID}"
fi

# Setting extra variables
GAME_EXE_OPTIONS="${exe_options}"

# Building user-writable prefix
init_userdirs
init_dosprefix

# Launching the game
cd "\${DOSPREFIX}"
dosbox -c "mount c .
c:
imgmount d \${GAME_IMAGE} -t iso -fs iso
\${GAME_EXE##*/} \${GAME_EXE_OPTIONS} \$@
exit"
sleep 1
clean_userdirs

exit 0
EOF
chmod 755 "${target}"
}

write_bin_dosbox_common() {
local target="$1"
cat > "${target}" << EOF
#!/bin/sh -e

clean_userdirs() {
cd "\${DOSPREFIX}"
clean_userdirs_partial "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES_POST}"
clean_userdirs_partial "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES_POST}"
clean_userdirs_partial "\${USERDIR_DATA}" "\${GAME_DATA_FILES_POST}"
rmdir --ignore-fail-on-non-empty "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}"
}

clean_userdirs_partial() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
		mkdir -p "\${target}/\${file%/*}"
		mv "\${file}" "\${target}/\${file}"
		ln -s "\${target}/\${file}" "\${file}"
	fi
done
}

init_userdirs() {
mkdir -p "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}" "\${USERDIR_DATA}"
cd "\${GAME_PATH}"
init_userdirs_partial_files "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_userdirs_partial_files "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
init_userdirs_partial_files "\${USERDIR_DATA}" "\${GAME_DATA_FILES}"
init_userdirs_partial_dirs "\${USERDIR_DATA}" "\${GAME_DATA_DIRS}"
}

init_userdirs_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	if ! [ -e "\${target}/\${dir}" ]; then
		if [ -e "\${GAME_PATH}/\${dir}" ]; then
			mkdir -p "\${target}/\${dir%/*}"
			cp -r "\${GAME_PATH}/\${dir}" "\${target}/\${dir}"
		else
			mkdir -p "\${target}/\${dir}"
		fi
	fi
done
}

init_userdirs_partial_files() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if ! [ -e "\${target}/\${file}" ]; then
		if [ -e "\${GAME_PATH}/\${file}" ]; then
			mkdir -p "\${target}/\${file%/*}"
			cp "\${GAME_PATH}/\${file}" "\${target}/\${file}"
		else
			mkdir -p "\${target}/\${file%/*}"
			touch "\${target}/\${file}"
		fi
	fi
done
}

init_dosprefix() {
if ! [ -e "\${DOSPREFIX}/\${GAME_EXE}" ]; then
	rm -rf "\${DOSPREFIX}"
	mkdir -p "\${DOSPREFIX}"
	cp -surf "\${GAME_PATH}"/* "\${DOSPREFIX}"
fi
for dir in \${GAME_CACHE_DIRS} \${GAME_CONFIG_DIRS} \${GAME_DATA_DIRS}; do
	rm -rf "\${DOSPREFIX}/\${dir}"
done
init_dosprefix_partial_files "\${USERDIR_CACHE}"
init_dosprefix_partial_files "\${USERDIR_CONFIG}"
init_dosprefix_partial_files "\${USERDIR_DATA}"
init_dosprefix_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_dosprefix_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
init_dosprefix_partial_dirs "\${USERDIR_DATA}" "\${GAME_DATA_DIRS}"
}

init_dosprefix_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	rm -rf "\${DOSPREFIX}/\${dir}"
	mkdir -p "\${DOSPREFIX}/\${dir%/*}"
	ln -s "\${target}/\${dir}" "\${DOSPREFIX}/\${dir}"
done
}

init_dosprefix_partial_files() {
local target="\$1"
cd "\${target}"
find . -type f | while read file; do
	rm -f "\${DOSPREFIX}/\${file}"
	mkdir -p "\${DOSPREFIX}/\${file%/*}"
	ln -s "\${target}/\${file}" "\${DOSPREFIX}/\${file}"
done
}
EOF
chmod 755 "${target}"
}

write_bin_native() {
local target="$1"
local exe="$2"
local exe_options="$3"
local ld_preload="$4"
local more_infos="$5"
shift 5
if [ -n "$1" ]; then
	local exe_description="$1"
else
	local exe_description="${exe##*/}"
fi
if [ -n "${more_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_bin')" "${exe_description}" "${more_infos}"
else
	printf '%s %s…\n' "$(l10n 'write_bin')" "${exe_description}"
fi
cat > "${target}" << EOF
#!/bin/sh -e

# Setting game-specific variables
GAME_ID="${GAME_ID}"
GAME_EXE="${exe}"
GAME_PATH="${PATH_GAME}"

# Setting extra variables
GAME_EXE_OPTIONS="${exe_options}"
LD_LIBRARY_PATH="${ld_preload}:\${LD_LIBRARY_PATH}"
GAME_EXE_PATH="\${GAME_PATH}/\${GAME_EXE}"

# Launching the game
cd "\${GAME_EXE_PATH%/*}"
export LD_LIBRARY_PATH
./"\${GAME_EXE_PATH##*/}" \${GAME_EXE_OPTIONS} \$@

exit 0
EOF
chmod 755 "${target}"
}

write_bin_native_prefix() {
local target="$1"
local exe="$2"
local exe_options="$3"
local ld_preload="$4"
local more_infos="$5"
shift 5
if [ -n "$1" ]; then
	local exe_description="$1"
else
	local exe_description="${exe##*/}"
fi
if [ -n "${more_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_bin')" "${exe_description}" "${more_infos}"
else
	printf '%s %s…\n' "$(l10n 'write_bin')" "${exe_description}"
fi
cat > "${target}" << EOF
#!/bin/sh -e

# Import essential functions
. "${PATH_BIN}/${APP_COMMON_ID}"

# Setting game-specific variables
GAME_ID="${GAME_ID}"
GAME_EXE="${exe}"
GAME_PATH="${PATH_GAME}"
GAME_CACHE_DIRS="${GAME_CACHE_DIRS}"
GAME_CACHE_FILES="${GAME_CACHE_FILES}"
GAME_CACHE_FILES_POST="${GAME_CACHE_FILES_POST}"
GAME_CONFIG_DIRS="${GAME_CONFIG_DIRS}"
GAME_CONFIG_FILES="${GAME_CONFIG_FILES}"
GAME_CONFIG_FILES_POST="${GAME_CONFIG_FILES_POST}"
GAME_DATA_DIRS="${GAME_DATA_DIRS}"
GAME_DATA_FILES="${GAME_DATA_FILES}"

# Setting prefix-specific variables
if [ -n "\${XDG_CACHE_HOME}" ]; then
	USERDIR_CACHE="\${XDG_CACHE_HOME}/\${GAME_ID}"
else
	USERDIR_CACHE="\${HOME}/.cache/\${GAME_ID}"
fi
if [ -n "\${XDG_CONFIG_HOME}" ]; then
	USERDIR_CONFIG="\${XDG_CONFIG_HOME}/\${GAME_ID}"
else
	USERDIR_CONFIG="\${HOME}/.config/\${GAME_ID}"
fi
if [ -n "\${XDG_DATA_HOME}" ]; then
	USERDIR_DATA="\${XDG_DATA_HOME}/games/\${GAME_ID}"
else
	USERDIR_DATA="\${HOME}/.local/share/games/\${GAME_ID}"
fi

# Setting extra variables
GAME_EXE_OPTIONS="${exe_options}"
LD_LIBRARY_PATH="${ld_preload}:\${LD_LIBRARY_PATH}"

# Building user-writable prefix
init_userdirs
init_prefix

# Launching the game
cd "\${USERDIR_DATA}"
export LD_LIBRARY_PATH
"\${GAME_EXE}" \${GAME_EXE_OPTIONS} \$@
sleep 1
clean_userdirs

exit 0
EOF
chmod 755 "${target}"
}

write_bin_native_prefix_common() {
local target="$1"
cat > "${target}" << EOF
#!/bin/sh -e

clean_userdirs() {
cd "\${USERDIR_DATA}"
clean_userdirs_partial "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES_POST}"
clean_userdirs_partial "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES_POST}"
rmdir --ignore-fail-on-non-empty "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}"
}

clean_userdirs_partial() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
		mkdir -p "\${target}/\${file%/*}"
		mv "\${file}" "\${target}/\${file}"
		ln -s "\${target}/\${file}" "\${file}"
	fi
done
}

init_userdirs() {
mkdir -p "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}" "\${USERDIR_DATA}"
cd "\${GAME_PATH}"
init_userdirs_partial_files "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_userdirs_partial_files "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
init_userdirs_partial_files "\${USERDIR_DATA}" "\${GAME_DATA_FILES}"
init_userdirs_partial_dirs "\${USERDIR_DATA}" "\${GAME_DATA_DIRS}"
}

init_userdirs_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	if ! [ -e "\${target}/\${dir}" ]; then
		if [ -e "\${GAME_PATH}/\${dir}" ]; then
			mkdir -p "\${target}/\${dir%/*}"
			cp -r "\${GAME_PATH}/\${dir}" "\${target}/\${dir}"
		else
			mkdir -p "\${target}/\${dir}"
		fi
	fi
done
}

init_userdirs_partial_files() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if ! [ -e "\${target}/\${file}" ]; then
		if [ -e "\${GAME_PATH}/\${file}" ]; then
			mkdir -p "\${target}/\${file%/*}"
			cp "\${GAME_PATH}/\${file}" "\${target}/\${file}"
		else
			mkdir -p "\${target}/\${file%/*}"
			touch "\${target}/\${file}"
		fi
	fi
done
}

init_prefix () {
cp -surf "\${GAME_PATH}"/* "\${USERDIR_DATA}"
for dir in \${GAME_CACHE_DIRS} \${GAME_CONFIG_DIRS}; do
	rm -rf "\${USERDIR_DATA}/\${dir}"
done
init_prefix_partial_files "\${USERDIR_CACHE}"
init_prefix_partial_files "\${USERDIR_CONFIG}"
init_prefix_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_prefix_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
}

init_prefix_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	rm -rf "\${USERDIR_DATA}/\${dir}"
	mkdir -p "\${USERDIR_DATA}/\${dir%/*}"
	ln -s "\${target}/\${dir}" "\${USERDIR_DATA}/\${dir}"
done
}

init_prefix_partial_files() {
local target="\$1"
cd "\${target}"
find . -type f | while read file; do
	rm -f "\${USERDIR_DATA}/\${file}"
	mkdir -p "\${USERDIR_DATA}/\${file%/*}"
	ln -s "\${target}/\${file}" "\${USERDIR_DATA}/\${file}"
done
}
EOF
chmod 755 "${target}"
}

write_bin_scummvm() {
local target="$1"
local scummid="$2"
local exe_options="$3"
local more_infos="$4"
shift 4
if [ -n "$1" ]; then
	local exe_description="$1"
else
	local exe_description="${exe##*/}"
fi
if [ -n "${more_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_bin')" "${exe_description}" "${more_infos}"
else
	printf '%s %s…\n' "$(l10n 'write_bin')" "${exe_description}"
fi
cat > "${target}" << EOF
#!/bin/sh -e

# Setting game-specific variables
GAME_ID="${scummid}"
GAME_PATH="${PATH_GAME}"

# Setting extra variables
GAME_EXE_OPTIONS="${exe_options}"

scummvm \${GAME_EXE_OPTIONS} \$@ -p "\${GAME_PATH}" \${GAME_ID}

exit 0
EOF
chmod 755 "${target}"
}

write_bin_wine() {
local target="$1"
local exe="$2"
local exe_options="$3"
local more_infos="$4"
shift 4
if [ -n "$1" ]; then
	local exe_description="$1"
else
	local exe_description="${exe##*/}"
fi
if [ -n "${more_infos}" ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_bin')" "${exe_description}" "${more_infos}"
else
	printf '%s %s…\n' "$(l10n 'write_bin')" "${exe_description}"
fi
cat > "${target}" << EOF
#!/bin/sh -e

# Import essential functions
. "${PATH_BIN}/${APP_COMMON_ID}"

# Setting game-specific variables
GAME_ID="${GAME_ID}"
GAME_EXE="${exe}"
GAME_PATH="${PATH_GAME}"
GAME_CACHE_DIRS="${GAME_CACHE_DIRS}"
GAME_CACHE_FILES="${GAME_CACHE_FILES}"
GAME_CACHE_FILES_POST="${GAME_CACHE_FILES_POST}"
GAME_CONFIG_DIRS="${GAME_CONFIG_DIRS}"
GAME_CONFIG_FILES="${GAME_CONFIG_FILES}"
GAME_CONFIG_FILES_POST="${GAME_CONFIG_FILES_POST}"
GAME_DATA_DIRS="${GAME_DATA_DIRS}"
GAME_DATA_FILES="${GAME_DATA_FILES}"
GAME_DATA_FILES_POST="${GAME_DATA_FILES_POST}"

# Setting prefix-specific variables
if [ -n "\${XDG_CACHE_HOME}" ]; then
	USERDIR_CACHE="\${XDG_CACHE_HOME}/\${GAME_ID}"
else
	USERDIR_CACHE="\${HOME}/.cache/\${GAME_ID}"
fi
if [ -n "\${XDG_CONFIG_HOME}" ]; then
	USERDIR_CONFIG="\${XDG_CONFIG_HOME}/\${GAME_ID}"
else
	USERDIR_CONFIG="\${HOME}/.config/\${GAME_ID}"
fi
if [ -n "\${XDG_DATA_HOME}" ]; then
	USERDIR_DATA="\${XDG_DATA_HOME}/games/\${GAME_ID}"
	WINEPREFIX="\${XDG_DATA_HOME}/wine/prefixes/\${GAME_ID}"
else
	USERDIR_DATA="\${HOME}/.local/share/games/\${GAME_ID}"
	WINEPREFIX="\${HOME}/.local/share/wine/prefixes/\${GAME_ID}"
fi
WINEARCH='win32'
WINEDEBUG='-all'
WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

# Setting extra variables
WINE_GAME_PATH="\${WINEPREFIX}/drive_c/\${GAME_ID}"
WINE_EXE_PATH="\${WINE_GAME_PATH}/\${GAME_EXE}"
GAME_EXE_OPTIONS="${exe_options}"

# Building user-writable prefix
init_userdirs
export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
init_wineprefix

# Launching the game
cd "\${WINE_EXE_PATH%/*}"
wine "\${WINE_EXE_PATH##*/}" \${GAME_EXE_OPTIONS} \$@
sleep 1
clean_userdirs

exit 0
EOF
chmod 755 "${target}"
}

write_bin_wine_cfg() {
local target="$1"
cat > "${target}" << EOF
#!/bin/sh -e

# Import essential functions
. "${PATH_BIN}/${APP_COMMON_ID}"

# Setting game-specific variables
GAME_ID="${GAME_ID}"
GAME_PATH="${PATH_GAME}"
GAME_CACHE_DIRS="${GAME_CACHE_FILES}"
GAME_CACHE_FILES="${GAME_CACHE_FILES}"
GAME_CACHE_FILES_POST="${GAME_CACHE_FILES_POST}"
GAME_CONFIG_DIRS="${GAME_CONFIG_DIRS}"
GAME_CONFIG_FILES="${GAME_CONFIG_FILES}"
GAME_CONFIG_FILES_POST="${GAME_CONFIG_FILES_POST}"
GAME_DATA_DIRS="${GAME_DATA_DIRS}"
GAME_DATA_FILES="${GAME_DATA_FILES}"
GAME_DATA_FILES_POST="${GAME_DATA_FILES_POST}"

# Setting prefix-specific variables
if [ -n "\${XDG_CACHE_HOME}" ]; then
	USERDIR_CACHE="\${XDG_CACHE_HOME}/\${GAME_ID}"
else
	USERDIR_CACHE="\${HOME}/.cache/\${GAME_ID}"
fi
if [ -n "\${XDG_CONFIG_HOME}" ]; then
	USERDIR_CONFIG="\${XDG_CONFIG_HOME}/\${GAME_ID}"
else
	USERDIR_CONFIG="\${HOME}/.config/\${GAME_ID}"
fi
if [ -n "\${XDG_DATA_HOME}" ]; then
	USERDIR_DATA="\${XDG_DATA_HOME}/games/\${GAME_ID}"
	WINEPREFIX="\${XDG_DATA_HOME}/wine/prefixes/\${GAME_ID}"
else
	USERDIR_DATA="\${HOME}/.local/share/games/\${GAME_ID}"
	WINEPREFIX="\${HOME}/.local/share/wine/prefixes/\${GAME_ID}"
fi
WINEARCH='win32'
WINEDEBUG='-all'
WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

# Setting extra variables
WINE_GAME_PATH="\${WINEPREFIX}/drive_c/\${GAME_ID}"

# Building user-writable prefix
init_userdirs
export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
init_wineprefix

# Launching WINE configuration screen
winecfg
sleep 1
clean_userdirs

exit 0
EOF
chmod 755 "${target}"
}

write_bin_wine_common() {
local target="$1"
cat > "${target}" << EOF
#!/bin/sh -e

clean_userdirs() {
cd "\${WINE_GAME_PATH}"
clean_userdirs_partial "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES_POST}"
clean_userdirs_partial "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES_POST}"
clean_userdirs_partial "\${USERDIR_DATA}" "\${GAME_DATA_FILES_POST}"
rmdir --ignore-fail-on-non-empty "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}"
}

clean_userdirs_partial() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
		mkdir -p "\${target}/\${file%/*}"
		mv "\${file}" "\${target}/\${file}"
		ln -s "\${target}/\${file}" "\${file}"
	fi
done
}

init_userdirs() {
mkdir -p "\${USERDIR_CACHE}" "\${USERDIR_CONFIG}" "\${USERDIR_DATA}"
cd "\${GAME_PATH}"
init_userdirs_partial_files "\${USERDIR_CACHE}" "\${GAME_CACHE_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_userdirs_partial_files "\${USERDIR_CONFIG}" "\${GAME_CONFIG_FILES}"
init_userdirs_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
init_userdirs_partial_files "\${USERDIR_DATA}" "\${GAME_DATA_FILES}"
init_userdirs_partial_dirs "\${USERDIR_DATA}" "\${GAME_DATA_DIRS}"
}

init_userdirs_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	if ! [ -e "\${target}/\${dir}" ]; then
		if [ -e "\${GAME_PATH}/\${dir}" ]; then
			mkdir -p "\${target}/\${dir%/*}"
			cp -r "\${GAME_PATH}/\${dir}" "\${target}/\${dir}"
		else
			mkdir -p "\${target}/\${dir}"
		fi
	fi
done
}

init_userdirs_partial_files() {
local target="\$1"
local files="\$2"
for file in \${files}; do
	if ! [ -e "\${target}/\${file}" ]; then
		if [ -e "\${GAME_PATH}/\${file}" ]; then
			mkdir -p "\${target}/\${file%/*}"
			cp "\${GAME_PATH}/\${file}" "\${target}/\${file}"
		else
			mkdir -p "\${target}/\${file%/*}"
			touch "\${target}/\${file}"
		fi
	fi
done
}

init_wineprefix() {
if ! [ -e "\${WINE_GAME_PATH}" ]; then
	rm -rf "\${WINEPREFIX}"
	mkdir -p "\${WINEPREFIX%/*}"
	wineboot -i 2>/dev/null
	rm "\${WINEPREFIX}/dosdevices/z:"
	mkdir "\${WINE_GAME_PATH}"
	cp -surf "\${GAME_PATH}"/* "\${WINE_GAME_PATH}"
fi
for dir in \${GAME_CACHE_DIRS} \${GAME_CONFIG_DIRS} \${GAME_DATA_DIRS}; do
	rm -rf "\${WINE_GAME_PATH}/\${dir}"
done
init_wineprefix_partial_files "\${USERDIR_CACHE}"
init_wineprefix_partial_files "\${USERDIR_CONFIG}"
init_wineprefix_partial_files "\${USERDIR_DATA}"
init_wineprefix_partial_dirs "\${USERDIR_CACHE}" "\${GAME_CACHE_DIRS}"
init_wineprefix_partial_dirs "\${USERDIR_CONFIG}" "\${GAME_CONFIG_DIRS}"
init_wineprefix_partial_dirs "\${USERDIR_DATA}" "\${GAME_DATA_DIRS}"
}

init_wineprefix_partial_dirs() {
local target="\$1"
local dirs="\$2"
for dir in \${dirs}; do
	rm -rf "\${WINE_GAME_PATH}/\${dir}"
	mkdir -p "\${WINE_GAME_PATH}/\${dir%/*}"
	ln -s "\${target}/\${dir}" "\${WINE_GAME_PATH}/\${dir}"
done
}

init_wineprefix_partial_files() {
local target="\$1"
cd "\${target}"
find . -type f | while read file; do
	rm -f "\${WINE_GAME_PATH}/\${file}"
	mkdir -p "\${WINE_GAME_PATH}/\${file%/*}"
	ln -s "\${target}/\${file}" "\${WINE_GAME_PATH}/\${file}"
done
}
EOF
chmod 755 "${target}"
}

write_desktop() {
local id="$1"
local name="$2"
local name_fr="$3"
local target="$4"
local cat="$5"
local fallback="$6"
local options="$7"
local lang="${LANG%_*}"
parse_options "${options}"
printf '%s %s…\n' "$(l10n 'write_desktop')" "${name}"
cat > "${target}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${name}
Name[fr]=${name_fr}
Icon=${id}
Exec=${id}
EOF
if [ "${opts_terminal}" = '1' ]; then
	printf 'Terminal=true\n' >> "${target}"
fi
if [ -n "${cat}" ]; then
	printf 'Categories=%s\n' "${cat}" >> "${target}"
fi
if [ -z "$(printf '%s' "${PATH}" | grep -e "${PATH_BIN}")" ]; then
	sed -i "s#Exec=${id}#Exec=${PATH_BIN}/${id}#" "${target}"
fi
if [ "${NO_ICON}" = '1' ] && [ -n "${fallback}" ]; then
	sed -i "s/Icon=${id}/Icon=${fallback}/" "${target}"
fi
}

write_menu() {
local id="$1"
local name="$2"
local name_fr="$3"
local cat="$4"
local target_dir="$5"
local target_merged="$6"
local fallback="$7"
shift 7
local id1="$1"
local id2="$2"
if [ $# -ge 3 ]; then local id3="$3"; fi
if [ $# -ge 4 ]; then local id4="$4"; fi
printf '%s %s…\n' "$(l10n 'write_menu')" "${name}"
cat > "${target_dir}" << EOF
[Desktop Entry]
Version=1.0
Type=Directory
Name=${name}
Name[fr]=${name_fr}
Icon=${id}
EOF
if [ "${NO_ICON}" = '1' ]; then
	sed -i "s/Icon=${id}/Icon=${fallback}/" "${target_dir}"
fi
cat > "${target_merged}" << EOF
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
	<Name>Applications</Name>
	<Menu>
		<Name>${cat}</Name>
		<Menu>
			<Name>${id}</Name>
			<Directory>${id}.directory</Directory>
			<Include>
				<Filename>${id1}.desktop</Filename>
				<Filename>${id2}.desktop</Filename>
EOF
if [ $# -ge 3 ]; then
cat >> "${target_merged}" << EOF
				<Filename>${id3}.desktop</Filename>
EOF
fi
if [ $# -ge 4 ]; then
cat >> "${target_merged}" << EOF
				<Filename>${id4}.desktop</Filename>
EOF
fi
cat >> "${target_merged}" << EOF
			</Include>
		</Menu>
	</Menu>
</Menu>
EOF
}

write_pkg_debian() {
local dir="$1"
local id="$2"
local version="$3"
local arch="$4"
local conflicts="$5"
local deps="$6"
local recs="$7"
local desc="$8"
local extra_infos="$9"
local size="$(du -cks $(realpath ${dir}/* | grep -v DEBIAN$) | tail -n1 | cut -f1)"
local maint="$(whoami)@$(hostname)"
local target="${dir}/DEBIAN/control"
if [ "${extra_infos}" = 'arch' ]; then
	printf '%s %s (%s)…\n' "$(l10n 'write_pkg_debian')" "$(printf '%s' "${desc}" | head -n1)" "${arch}"
else
	printf '%s %s…\n' "$(l10n 'write_pkg_debian')" "$(printf '%s' "${desc}" | head -n1)"
fi
cat > "${target}" << EOF
Package: ${id}
Version: ${version}
Architecture: ${arch}
Maintainer: ${maint}
Installed-Size: ${size}
EOF
if [ -n "${conflicts}" ]; then
	printf 'Conflicts: %s\n' "${conflicts}" >> "${target}"
fi
printf 'Depends: %s\n' "${deps}" >> "${target}"
if [ -n "${recs}" ]; then
	printf 'Recommends: %s\n' "${recs}" >> "${target}"
fi
cat >> "${target}" << EOF
Section: non-free/games
Description: ${desc}
EOF
}

export STRINGS_BANK='
build_pkg:en:Building package for
build_pkg:fr:Construction du paquet pour
build_pkg_dirs:en:Building package directories
build_pkg_dirs:fr:Construction de l’arborescence du paquet
build_pkgs:en:Building packages
build_pkgs:fr:Construction des paquets
build_linux_client:en:Building Linux client
build_linux_client:fr:Mise en place du client Linux
build_movies:en:Building movies support
build_movies:fr:Mise en place de la gestion des films
build_generic:en:Building
build_generic:fr:Construction de
check_deps:en:Checking dependencies
check_deps:fr:Contrôle des dépendances
check_deps_error:en:Install it before running this script
check_deps_error:fr:Installez-le avant de lancer ce script
check_deps_icons_1_icoutils:en:This command is provided by the icoutils package
check_deps_icons_1_icoutils:fr:Cette commande est fournie par le paquet icoutils
check_deps_icons_1_imagemagick:en:This command is provided by the imagemagick package
check_deps_icons_1_imagemagick:fr:Cette commande est fournie par le paquet imagemagick
check_deps_icons_2:en:You can go on with the script execution by skipping the icons extraction, or stop it to install the missing package
check_deps_icons_2:fr:Vous pouvez poursuivre l’exécution de ce script en sautant l’étape d’extraction des icônes, ou l’interrompre pour installer le paquet manquant
checksum:en:Checking integrity of
checksum:fr:Contrôle de l’intégrité de
checksum_error_1:en:Hashsum mismatch
checksum_error_1:fr:Somme de contrôle incohérente
checksum_error_2:en:is not the expected file, or it is corrupted
checksum_error_2:fr:n’est pas le fichier attendu, ou il est corrompu
checksum_multiple:en:Checking target files integrity
checksum_multiple:fr:Contrôle de l’intégrité des fichiers cibles
continue:en:Continue? [Y/n]
continue:fr:Continuer ? [O/n]
extract_data:en:Extracting data from
extract_data:fr:Extraction des données depuis
extract_data_generic:en:Extracting data
extract_data_generic:fr:Extraction des données
extract_data_no_type:en:Archive type not specified
extract_data_no_type:fr:Type de l’archive non-spécifié
extract_data_unknown_type:en:archive type unknown
extract_data_unknown_type:fr:type d’archive inconnu
extract_icons:en:Extracting icons from
extract_icons:fr:Extraction des icônes depuis
extract_icons_error:en:Unknown icon type
extract_icons_error:fr:Type d’icône non reconnu
fix_rights:en:Fixing file rights
fix_rights:fr:Harmonisation des droits sur les fichiers
have_fun:en:Have fun
have_fun:fr:Bon jeu
help_checksum:en:Set the checksum method for the target files
help_checksum:fr:Choix de la méthode de vérification de l’intégrité des fichiers cibles
help_compression:en:Set the compression method for the final package
help_compression:fr:Choix de la méthode de compression du paquet final
help_default:en:default value
help_default:fr:valeur par défaut 
help_lang:en:Set the language of the game
help_lang:fr:Définition de la langue du jeu
help_lang_txt:en:Set the language of the texts
help_lang_txt:fr:Définition de la langue des textes
help_lang_voices:en:Set the language of the voices
help_lang_voices:fr:Définition de la langue des voix
help_lang_de:en:de: German
help_lang_de:fr:de : allemand
help_lang_en:en:en: English
help_lang_en:fr:en : anglais
help_lang_es:en:es: Spanish
help_lang_es:fr:es : espagnol
help_lang_fr:en:fr: French
help_lang_fr:fr:fr : français
help_lang_it:en:it: Italian
help_lang_it:fr:it : italien
help_lang_nl:en:nl: Dutch
help_lang_nl:fr:nl : néerlandais
help_lang_pl:en:pl: Polish
help_lang_pl:fr:pl : polonais
help_lang_sv:en:sv: Swedish
help_lang_sv:fr:sv : suédois
help_movies:en:Build the final package with movies support
help_movies:fr:Construit le paquet final avec le support des vidéos
help_movies_default:en:disabled by default
help_movies_default:fr:désactivé par defaut
help_prefix:en:Set the installation prefix. "DIR" must be an absolute path
help_prefix:fr:Choix du préfixe d’installation. "DIR" doit être un chemin absolu
install_instructions_1:en:Install
install_instructions_1:fr:Installez
install_instructions_2:en:by running the following commands as root
install_instructions_2:fr:en lançant la série de commandes suivante en root 
interruption:en:Script interrupted
interruption:fr:Script interrompu
interruption_icons:en:Game icons will not be extracted
interruption_icons:fr:Les icônes du jeu ne seront pas extraites
movies_build_deps:en:The following packages are required to build movie support
movies_build_deps:fr:Les paquets suivants sont nécessaires pour compiler la gestion des films 
movies_disabled:en:Movies handling disabled; add --with-movies to enable it
movies_disabled:fr:Gestion des films désactivée ; ajoutez --with-movies pour l’activer
movies_enabled:en:Movies handling enabled
movies_enabled:fr:Gestion des films activée
not_found:en:not found
not_found:fr:est introuvable
not_found_multiple:en:not found
not_found_multiple:fr:sont introuvables
option_ignored:en:It will be ignored
option_ignored:fr:Elle sera ignorée
option_unknown:en:unknown option
option_unknown:fr:option inconnue
option_unsupported:en:option not supported by this script
option_unsupported:fr:option non gérée par ce script
pkgs_not_found_1:en:None of these packages has been found
pkgs_not_found_1:fr:Aucun de ces paquets n’a pu être trouvé 
pkgs_not_found_2:en:Install one of these before running this script
pkgs_not_found_2:fr:Installez l’un d’entre eux avant de lancer ce script
print_done:en:Done.
print_done:fr:Fait.
print_error:en:Error:
print_error:fr:Erreur :
print_wait:en:This might take several minutes.
print_wait:fr:Cette étape peut durer plusieurs minutes.
print_warning:en:Warning:
print_warning:fr:Avertissement :
set_checksum:en:Checksum method set to
set_checksum:fr:Méthode de vérification du fichier cible définie à 
set_compression:en:Compression method set to
set_compression:fr:Méthode de compression du paquet final définie à 
set_lang:en:Game language set to
set_lang:fr:Langue du jeu définie à 
set_lang_txt:en:Texts language set to
set_lang_txt:fr:Langue des textes définie à 
set_lang_voices:en:Voices language set to
set_lang_voices:fr:Langue des voix définie à 
set_prefix:en:Installation prefix set to
set_prefix:fr:Préfixe d’installation défini à 
set_prefix_error:en:The value assigned to --prefix must be an absolute path
set_prefix_error:fr:La valeur assignée à --prefix doit être un chemin absolu
set_target:en:Looking for target files
set_target:fr:Recherche des fichiers cibles
set_target_missing:en:This script needs to be given the path to the archive downloaded from
set_target_missing:fr:Ce script prend en argument le chemin vers l’archive téléchargée depuis
set_target_extra_missing:en:It must be located in the same directory than
set_target_extra_missing:fr:Il doit se trouver dans le même répertoire que
set_target_extra_missing_url:en:You can download it from the following URL
set_target_extra_missing_url:fr:Vous pouvez le télécharger à l’adresse suivante 
set_target_extra_missing_multiple:en:On of these files must be located in the same directory than
set_target_extra_missing_multiple:fr:Un de ces fichiers doit se trouver dans le même répertoire que
set_target_extra_missing_multiple_url:en:You can download them from the following URL
set_target_extra_missing_multiple_url:fr:Vous pouvez les télécharger à l’adresse suivante 
tolower:en:Converting filenames to lowercase
tolower:fr:Harmonisation de la casse des noms de fichiers
using:en:Using
using:fr:Utilisation de
value_accepted:en:Accepted values are
value_accepted:fr:Les valeurs acceptées sont 
value_default:en:Default value is
value_default:fr:La valeur par défaut est 
value_invalid:en:is not a valid value for
value_invalid:fr:n’est pas une valeur valide pour
write_bin:en:Writing launcher script for
write_bin:fr:Écriture du script de lancement pour
write_desktop:en:Writing menu entry for
write_desktop:fr:Écriture de l’entrée de menu pour
write_menu:en:Writing menu for
write_menu:fr:Écriture du menu pour
write_pkg_debian:en:Writing package meta-data for
write_pkg_debian:fr:Écriture des méta-données du paquet pour
'
