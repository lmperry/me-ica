# Generated by Neurodocker v0.2.0-12-g1a1c6f6.
#
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
#     https://github.com/kaczmarj/neurodocker
#
# Timestamp: 2017-08-30 19:05:17

FROM ubuntu:trusty

ARG DEBIAN_FRONTEND=noninteractive

#----------------------------------------------------------
# Install common dependencies and create default entrypoint
#----------------------------------------------------------
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN apt-get update -qq && apt-get install -yq --no-install-recommends  \
    	bzip2 ca-certificates curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> $ND_ENTRYPOINT \
         && echo 'set +x' >> $ND_ENTRYPOINT \
         && echo 'if [ -z "$*" ]; then /usr/bin/env bash; else $*; fi' >> $ND_ENTRYPOINT; \
       fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker
ENTRYPOINT ["/neurodocker/startup.sh"]

RUN apt-get update -qq && apt-get install -yq --no-install-recommends git vim libxml2-dev libnlopt-dev libxslt-dev\
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--------------------
# Install AFNI latest
#--------------------
ENV PATH=/opt/afni:$PATH
RUN apt-get update -qq && apt-get install -yq --no-install-recommends ed gsl-bin libglu1-mesa-dev libglib2.0-0 libglw1-mesa \
    libgomp1 libjpeg62 libxm4 netpbm tcsh xfonts-base xvfb \
    && libs_path=/usr/lib/x86_64-linux-gnu \
    && if [ -f $libs_path/libgsl.so.19 ]; then \
           ln $libs_path/libgsl.so.19 $libs_path/libgsl.so.0; \
       fi \
    # Install libxp (not in all ubuntu/debian repositories) \
    && apt-get install -yq --no-install-recommends libxp6 \
    || /bin/bash -c " \
       curl --retry 5 -o /tmp/libxp6.deb -sSL http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
       && dpkg -i /tmp/libxp6.deb && rm -f /tmp/libxp6.deb" \
    # Install libpng12 (not in all ubuntu/debian repositories) \
    && apt-get install -yq --no-install-recommends libpng12-0 \
    || /bin/bash -c " \
       curl -o /tmp/libpng12.deb -sSL http://mirrors.kernel.org/debian/pool/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
       && dpkg -i /tmp/libpng12.deb && rm -f /tmp/libpng12.deb" \
    # Install R \
    && apt-get install -yq --no-install-recommends \
    	r-base-dev r-cran-rmpi \
     || /bin/bash -c " \
        curl -o /tmp/install_R.sh -sSL https://gist.githubusercontent.com/kaczmarj/8e3792ae1af70b03788163c44f453b43/raw/0577c62e4771236adf0191c826a25249eb69a130/R_installer_debian_ubuntu.sh \
        && /bin/bash /tmp/install_R.sh" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni \
    && curl -sSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar zx -C /opt/afni --strip-components=1 \
    && /opt/afni/rPkgsInstall -pkgs ALL \
    && rm -rf /tmp/*

# Create new user: neuro
RUN useradd --no-user-group --create-home --shell /bin/bash neuro
USER neuro

#------------------
# Install Miniconda
#------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH
RUN echo "Downloading Miniconda installer ..." \
    && miniconda_installer=/tmp/miniconda.sh \
    && curl -sSL -o $miniconda_installer https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && /bin/bash $miniconda_installer -f -b -p $CONDA_DIR \
    && rm -f $miniconda_installer \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda update -y -q --all && sync \
    && conda clean -tipsy && sync

#-----------------------------
# Create py3 conda environment
#-----------------------------
RUN conda create -y -q --name default --channel vida-nyu python=3.6.1 \
    	numpy pandas reprozip traits \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate default \
    	&& pip install -q --no-cache-dir \
    	nipype ipython scikit-learn scipy ipdb mdp" \
    && sync
ENV PATH=/opt/conda/envs/default/bin:$PATH

#------------------------------
# Create py27 conda environment
#------------------------------
RUN conda create -y -q --name py27 python=2.7 \
    numpy pandas reprozip traits \
    && sync && conda clean -tipsy && sync \
    && /bin/bash -c "source activate default \
        && pip install -q --no-cache-dir \
        nipype ipython scikit-learn scipy ipdb mdp" \
    && sync

USER root

# User-defined instruction
RUN mkdir /home/neuro/code

# User-defined instruction
RUN mkdir /home/neuro/data

WORKDIR /home/neuro
