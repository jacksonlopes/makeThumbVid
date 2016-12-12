#!/bin/bash
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Jackson Lopes <jacksonlopes@gmail.com>
# Personal site: https://jacksonlopes.github.io
# Info/Source: https://makeThumbVid.github.io | https://github.com/jacksonlopes/makeThumbVid

# Dependencies | Dependências:
# ffprobe, ffmpeg, mplayer, ImageMagick {montage/convert}
ffprobe="/usr/bin/ffprobe"
ffmpeg="/usr/bin/ffmpeg"
mediainfo="/usr/bin/mediainfo"
mplayer="/usr/bin/mplayer"
montage="/usr/bin/montage"
convert="/usr/bin/convert"

ERROR=1
SUCESS=0

version="1.0"
script_name="makeThumbVid"
site="https://makeThumbVid.github.io"
name_video=""
name_video_constant=""
# get filename | obtem apenas o nome do arquivo
name_video=""
num_images=16 # Default 10... | Padrão 10
num_columns=4 # Default 4...  | Padrão  4
num_seconds_movie=0
info_video=""
tmp_dir="/tmp/$script_name"

# Customize | Personalize
# http://www.imagemagick.org/Usage/montage/#controls
# http://www.imagemagick.org/Usage/annotating/
color_info="YellowGreen" # Khaki, Orange, Plum, YellowGreen, Gold, black, ...

# Functions | Funções
# Write log stdout | Escreve informmações em stdout
function log() {
   echo "[`date +%d/%m/%Y-%T`] - $*"
}

# Check for programs | Verifica se programas existem
function check_programs() {
   [ ! -d $tmp_dir ] && {
     mkdir $tmp_dir
     if [ $? != 0 ]; then
       log "Error create '$tmp_dir'" ; exit $ERROR 
     fi
   }
   
   for A in $ffmpeg $mplayer $montage $convert; do
     [ ! -f $A ] && { 
       log "$A [NOT EXIST]" ; exit $ERROR 
     }    
   done
   if [ "$type_info" = "" -o "$type_info" = "ff" ]; then
      [ ! -f "$ffprobe" ] && {
        log "$ffprobe [NOT EXIST]" ; exit $ERROR 
      }  
   elif [ ! -f "$mediainfo" ]; then
      log "$mediainfo [NOT EXIST]" ; exit $ERROR
   fi
   
}

# Check for video | Verifica se o video existe
function check_video() {
   [ ! -f "$1" ] && { 
     log "$1 [FILE NOT EXIST]" ; exit $ERROR 
   }
}

# Get info video | Obtém informações sobre o video
function get_info_video() {
   # thanks | Agradecimentos:
   # http://stackoverflow.com/questions/19013536/how-to-get-video-duration-in-seconds
   num_seconds_movie=`$ffmpeg -i "$1" 2>&1 | awk '/Duration/ {split($2,a,":");print a[1]*3600+a[2]*60+a[3]}'`
   # approximate | aproximado.
   num_seconds_movie=`echo $num_seconds_movie / $num_images | bc`
   
   if [ "$type_info" = "" -o "$type_info" = "ff" ]; then
      #ffprobe
      info_video=`$ffprobe -i "$1" -hide_banner -pretty 2>&1 | tail -n+2`
   else   
      # Create info by mediainfo | Se quiser o cabeçalho via mediainfo
      info_video=`$mediainfo "$1" | head -n+12 | tail -n10` 
      info_video=`echo "$info_video \n"``$mediainfo "$1" | grep Width` 
      info_video=`echo "$info_video \n"``$mediainfo "$1" | grep Height` 
      info_video=`echo "$info_video \n"``$mediainfo "$1" | grep Format/Info | tail -1`    
   fi   
   
   [ "$num_seconds_movie" = "" ] && {
     log "Error getting SECONDS..." ; exit $ERROR 
   }
}

# Complete path | Completa o path do video se necessário
function determine_path() {
  first_position=`echo "$1" | cut -c1`
  if [ "$first_position" != "/" ]; then
    v="${PWD}/$v"
  fi  
}

# Generate thumbnail | Gera o thumbnail
function generate_thumb() {
   cd $tmp_dir
   log "* mplayer..."
   $mplayer -vo jpeg -sstep $num_seconds_movie -frames $num_images "$1" > /dev/null 2>&1
   log "* montage..."
   $montage 00*.jpg -pointsize 8 -size 256x256 -thumbnail 256x256 -colors 255 -depth 8 -define png:compression-level=5 -geometry +3+3 -tile ${num_columns}x -sampling-factor 3x1 -quality 2 -border 1 ${name_video}_${script_name}_Thumbnail_tmp.png 2>/dev/null
   log "* convert..."
   $convert ${name_video}_${script_name}_Thumbnail_tmp.png -background $color_info label:"$info_video" +swap -gravity NorthWest -append label:"$make_by" -append -gravity south ${name_video}_${script_name}_Thumbnail.png 2>/dev/null
   mv ${name_video}_${script_name}_Thumbnail.png $OLDPWD
   log "* clean..."
   rm 000*.jpg
   rm ${name_video}_${script_name}_Thumbnail_tmp.png
   cd $OLDWD
}

# Set options for video | Seta opções para o thumbnail
function set_options_video() {
  # space to _ | troca espaço por _
  name_video=`basename "$1" | tr ' ' '_'`
  name_video_constant=$name_video
  # get filename | obtem apenas o nome do arquivo
  name_video="${name_video%.*}"
  make_by="Movie: $name_video_constant  |  make by '$script_name', v$version :: $site ::"
}

# Help | Ajuda
function help() {
   echo "Usage: $script_name -v <VIDEO> [-n <NUM_IMAGES>] [-c <NUM_COLUMNS>] [-t <TYPE_INFO>]"
   echo "Example: "
   echo " $script_name -v /home/myuser/myvideo.mp4                  # DEFAULT num_images = $num_images|num_columns = $num_columns|type_info = mplayer"
   echo " $script_name -v /home/myuser/myvideo.mp4 -n 20            # 20 images in result..."
   echo " $script_name -v /home/myuser/myvideo.mp4 -c 5             # 5 columns in result..."
   echo " $script_name -v /home/myuser/myvideo.mp4 -n 20 -c 5       # 20 images in result and 5 columns..."
   echo " $script_name -v /home/myuser/myvideo.mp4 -n 20 -c 5 -t ff # 20 images in result and 5 columns, info by ffprobe"
   echo " $script_name -v /home/myuser/myvideo.mp4 -n 20 -c 5 -t mi # 20 images in result and 5 columns, info by mediainfo"
   exit $ERROR
}

# Check options | Verifica opções informadas
function check_option() {
   [ "$1" = "" ] && {
     help
   }
}

# Main | Função principal
function main() {   
   log "Checking path prog..."
   check_programs
   log "Checking path video..."
   check_video "$1"
   log "Get info video..."
   get_info_video "$1"
   log "Generate thumbnail..."
   generate_thumb "$1"
}

while getopts ":v:n:c:t:h" opt; do
   case "${opt}" in
     v) 
       v=${OPTARG}
       check_option "$v"
       determine_path "$v"
       set_options_video "$v"
       ;;
     n)
       n=${OPTARG}
       check_option "$n"
       num_images=$n
       ;; 
     c)
       c=${OPTARG}
       check_option "$c"
       num_columns=$c
       ;;
     t)
       t=${OPTARG}
       check_option "$t"
       type_info=$t
       ;;       
     *|h)
       help
       ;;
   esac     
done

[ "$1" = "" -o "$v" = ""  ] && {
  help
}

# init... | início
main "$v"
log "Generated: '${name_video}_${script_name}_Thumbnail.png'"
exit $SUCESS
