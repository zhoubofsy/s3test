#!/bin/bash

result="result.log"

begin()
{
    echo "$1" >> ./${result}
}

end()
{
    echo "----------------------------" >> ./${result}
}

exec_s3()
{
    echo -n ">>> " >> ./${result}
    echo "$1" >> ./${result}
    echo -n "<<< " >> ./${result}
    echo `$1 >> ./${result} 2>&1`
}

check()
{
    if [ "$#" -ne 2 ]; then
        echo "Param Error !"
    fi
    begin "$1"
    exec_s3 "$2"
    end
}

check_base()
{
    # prepare env
    bkt="basebkt"
    tfile="testfile"
    echo "Hello Checker !" > ./${tfile}

    # create bucket
    check "bucket create:" "s3cmd mb s3://${bkt}"

    # list object
    check "list object:" "s3cmd ls"

    # put object
    check "put object:" "s3cmd put ./${tfile} s3://${bkt}/${tfile}"

    # get object
    check "get object:" "s3cmd get -f s3://${bkt}/${tfile} ./${tfile}.download"

    # copy object
    check "copy object:" "s3cmd cp s3://${bkt}/${tfile} s3://${bkt}/copyfolder/${tfile}"

    # move object
    check "move object:" "s3cmd mv s3://${bkt}/${tfile} s3://${bkt}/movefolder/${tfile}"

    # la object
    check "list all object:" "s3cmd la s3://${bkt}"

    # disk usage
    check "display disk usage:" "s3cmd du s3://${bkt}"

    # get info
    # bucket
    check "display info:" "s3cmd info s3://${bkt}"
    # object
    check "display info:" "s3cmd info s3://${bkt}/${tfile}"

    # delete object
    check "delete object:" "s3cmd rm s3://${bkt}/${tfile}"

    # remove bucket
    check "remove bucket:" "s3cmd rb -rf s3://${bkt}"
    
    # clean env
    rm -vf ./${tfile} ./${tfile}.download
}

check_sync()
{
    srcbkt="srcbkt"
    destbkt="destbkt"
    tfile="testfile"

    echo "SyncCheck" > ./${tfile}
    begin "Synchronize:"
    exec_s3 "s3cmd mb s3://${srcbkt}"
    exec_s3 "s3cmd mb s3://${destbkt}"
    exec_s3 "s3cmd put ./${tfile} s3://${srcbkt}/testfolder/${tfile}"
    exec_s3 "s3cmd info s3://${srcbkt}/testfolder/${tfile}"
    exec_s3 "s3cmd sync s3://${srcbkt}/testfolder s3://${destbkt}"
    exec_s3 "s3cmd ls s3://${destbkt}/testfolder/"
    exec_s3 "s3cmd info s3://${destbkt}/testfolder/${tfile}"
    exec_s3 "s3cmd rb -rf s3://${srcbkt}"
    exec_s3 "s3cmd rb -rf s3://${destbkt}"
    end    
    rm -vf ./${tfile}
}

check_acl()
{
    bkt="aclbkt" 
    tfile="testfile"

    echo "ACL test" > ./${tfile}
    begin "ACL:"
    exec_s3 "s3cmd mb s3://${bkt}"
    exec_s3 "s3cmd put --acl-private ./${tfile} s3://${bkt}/${tfile}"
    exec_s3 "s3cmd info s3://${bkt}/${tfile}"
    exec_s3 "s3cmd setacl --acl-revoke=full_control:topo-dev s3://${bkt}/${tfile}"
    exec_s3 "s3cmd info s3://${bkt}/${tfile}"
    exec_s3 "s3cmd setacl --acl-grant=read:topo-dev s3://${bkt}/${tfile}"
    exec_s3 "s3cmd info s3://${bkt}/${tfile}"
    exec_s3 "s3cmd rb -rf s3://${bkt}"
    end
    rm -vf ./${tfile}
}

check_cors()
{
    bkt="corsbkt"
    corsfile="corsfile"

    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><CORSConfiguration xmlns=\"http://los-cn-north-2.lecloudapis.com/${bkt}\"><CORSRule><AllowedOrigin>*</AllowedOrigin><AllowedMethod>GET</AllowedMethod><AllowedMethod>POST</AllowedMethod><AllowedMethod>PUT</AllowedMethod><MaxAgeSeconds>3000</MaxAgeSeconds><AllowedHeader>*</AllowedHeader></CORSRule></CORSConfiguration>" > ./${corsfile}
    begin "CORS:"
    exec_s3 "s3cmd mb s3://${bkt}"
    exec_s3 "s3cmd info s3://${bkt}"
    # set cors
    exec_s3 "s3cmd setcors ./${corsfile} s3://${bkt}"
    exec_s3 "s3cmd info s3://${bkt}"
    # delete cors
    exec_s3 "s3cmd delcors s3://${bkt}"
    exec_s3 "s3cmd info s3://${bkt}"
    exec_s3 "s3cmd rb -rf s3://${bkt}"
    end
    rm -vf ./${corsfile}
}

check_mp()
{
    bkt="mpbkt"
    tfile="testfile"

    dd if=/dev/zero of=./${tfile} bs=1MB count=300
    begin "Multipart:"
    exec_s3 "s3cmd mb s3://${bkt}"
    s3cmd put ./${tfile} s3://${bkt} > /dev/zero 2>&1 &

    # show multipart
    sleep 10s
    exec_s3 "s3cmd multipart s3://${bkt}"
    sleep 5s
    # list parts
    for id in `s3cmd multipart s3://${bkt} | awk '!/^s3:\/\/${bkt}|^Initiated/{print $3}'`
    do
        exec_s3 "s3cmd listmp s3://${bkt}/${tfile} ${id}"
    done
    sleep 5s
    # abort
    for id in `s3cmd multipart s3://${bkt} | awk '!/^s3:\/\/${bkt}|^Initiated/{print $3}'`
    do
        exec_s3 "s3cmd abortmp s3://${bkt}/${tfile} ${id}"
    done

    exec_s3 "s3cmd put ./${tfile} s3://${bkt}"
    exec_s3 "s3cmd info s3://${bkt}/${tfile}"

    exec_s3 "s3cmd rb -rf s3://${bkt}"
    end
    rm -vf ./${tfile}
}

main()
{
    echo "================  start  ==================" > ./${result}

    # check base operations
    check_base

    # check sync
    check_sync

    # check acl
    check_acl

    # check CORS
    check_cors

    # check multipart
    check_mp

    echo "================   end   ==================" >> ./${result}
}

main

