git clone https://github.com/STMicroelectronics/OpenOCD.git openocd_src
cd openocd_src
./bootstrap
./configure --enable-stlink --prefix=$(pwd)/../openocd
make -j$(nproc)
make install
rm -rf openocd_src
