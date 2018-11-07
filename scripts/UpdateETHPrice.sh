#!/bin/sh

cd ~/PARToken/SmartContract

export PATH=$PATH:/usr/local/bin

echo "*************************************************************************"

echo "`date "+[%Y-%m-%d %H:%M:%S]"` Starting Ropsten..."
/usr/local/bin/truffle exec scripts/UpdateETHPrice.js --network ropsten `tail -1 scripts/ethprice.dat|awk -F ',' '{print $2}'`
echo "`date "+[%Y-%m-%d %H:%M:%S]"` Ropsten Finished."

# echo "`date "+[%Y-%m-%d %H:%M:%S]"` Starting Mainnet..."
# /usr/local/bin/truffle exec scripts/UpdateETHPrice.js --network mainnet `tail -1 scripts/ethprice.dat|awk -F ',' '{print $2}'`
# echo "`date "+[%Y-%m-%d %H:%M:%S]"` Mainnet Finished."

cd - 1>/dev/null 2>&1
