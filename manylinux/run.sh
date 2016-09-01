
for ARCH in i686 x86_64; do 
    docker build --pull=true  --rm=true -t simpleitk_manylinux_${ARCH} -f Dockerfile-${ARCH} .

    if [ -n "$ExternalData_OBJECT_STORES" -a -d "$ExternalData_OBJECT_STORES" ] ; then
        external_data_args="-v ${ExternalData_OBJECT_STORES}:/var/io/.ExternalData -e ExternalData_OBJECT_STORES=/var/io/.ExternalData"
    fi

    docker run --rm -e USER=$USER  -e USERID=$UID -u=$UID $external_data_args -v $(pwd):/var/io -t simpleitk_manylinux_${ARCH}

    # use this command to debug
    #docker run --rm -i -t --entrypoint=/bin/bash -u=root $external_data_args -v $(pwd):/var/io simpleitk_manylinux_${ARCH}
done
