# If playlist.tsv is not found, get the latest version from ~/Downloads
if [ ! -f playlist.tsv ]; then
    echo "retrieving file $(ls ~/Downloads/*.tsv -1)";
    mv "$(ls ~/Downloads/*.tsv -1 | tail -1)" ./playlist.tsv
    # Removes 2 header lines 
    tail -n +3 playlist.tsv > playlist.tmp && mv playlist.tmp playlist.tsv;
fi

# Places a timestamp on the log file
echo "---------- $@: $(date | awk -F " " '{print $3 " " $2 " " $6 " " $4}') ----------" >> out.txt;

# mode: -   downloads:
# 0     -   Consider col 2
# 1     -   Ignore col 2

# Whole file
if [ "$1" = '-all' ]; then
    # Ignore col 2
    if [ "$2" != '-marked' ]; then
        mode=1;
    # Consider col 2
    else
        mode=0;
    fi
    command="cat playlist.tsv";
# Line sequence
elif [ "$1" = '-seq' ]; then
    # Ignore col 2
    if [ "$2" != '-marked' ]; then
        mode=1;
    # Consider col 2
    else
        shift 1;
        mode=0;
    fi
    # sed sequence format: ${from},${to}p
    line1=$(( $2 + 1 ));
    line2=$(( $3 + 1 ));
    line3=$(( $line2 + 1 ));
    string="${line1},${line2}p;${line3}q";
    command="sed -n $string playlist.tsv";
# Scattered lines
elif [ "$1" = '-each' ]; then
    # Ignore col 2
    if [ "$2" != '-marked' ]; then
        mode=1;
    # Consider col 2
    else
        shift 1;
        mode=0;
    fi
    shift 1;
    # sed multiple lines format ${a}p;${b}p;...;${n}pq;
    string="";
    for line in $@; do
        line1=$(( $line + 1 ));
        string+="${line1}p;";
    done
    line2=$(( $line1 + 1 ));
    string+="${line2}q;";
    command="sed -n $string playlist.tsv";
# single line && always ignore col 2
else
    mode=1;
    line1=$(( $1 + 1 ));
    string="${line1}p";
    command="sed -n $string playlist.tsv";
fi

if [ $mode = 0 ]; then
    $command | awk -F $'\t' '
    BEGIN {count=0;}
    {
        # If marked
        if ($2 == 1) {    
            seq[count]=$1;
            title[count]=$3;
            serie[count]=$4;
            version[count]=$5;
            link[count]=$6;
            # Transforms 1 into 001
            cmd="printf \"%03d\" " seq[count];
            cmd | getline pcount;
            close(cmd)
            # Case empty version (just so there are no extra spaces)
            if ($5 == "") {
                string= "youtube-dl -x --audio-format mp3 -i --audio-quality 0 -o " "\"" pcount " " \
                title[count] " - " serie[count] ".$%(ext)s" "\"" " " "\"" link[count] "\" >> out.txt";
            # Case existing versions
            } else {
                string= "youtube-dl -x --audio-format mp3 -i --audio-quality 0 -o " "\"" pcount " " title[count] \
                " - " serie[count] " " version[count] ".$%(ext)s" "\"" " " "\"" link[count] "\" >> out.txt";
            }
            if ($6 == "") {
                print "Empty link in line " NR-1 ": " $0
            } else {
                print string;
                print "down.sh" string >> "out.txt"
                system(string);
                count++;
            }
        }
    }'; 
else 
    $command | awk -F $'\t' '
    BEGIN {count=0;}
    {
        seq[count]=$1;
        title[count]=$3;
        serie[count]=$4;
        version[count]=$5;
        link[count]=$6;
        # Transforms 1 into 001
        cmd="printf \"%03d\" " seq[count];
        cmd | getline pcount;
        close(cmd)
        # Case empty version (just so there are no extra spaces)
        if ($5 == "") {
            string= "youtube-dl -x --audio-format mp3 -i --audio-quality 0 -o " "\"" pcount " " \
            title[count] " - " serie[count] ".$%(ext)s" "\"" " " "\"" link[count] "\" >> out.txt";
        # Case existing versions
        } else {
            string= "youtube-dl -x --audio-format mp3 -i --audio-quality 0 -o " "\"" pcount " " title[count] \
            " - " serie[count] " " version[count] ".$%(ext)s" "\"" " " "\"" link[count] "\" >> out.txt";
        }
        if ($6 == "") {
            print "Empty link in line " NR-1 ": " $0
        } else {
            print string;
            print "down.sh" string >> "out.txt"
            system(string);
            count++;
        }
    }';
fi

# Youtube-dl sends all error messages in stdout regardless of the rederection, but just in case
grep -A5 -B5 -i -s "error" out.txt
