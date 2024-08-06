import { LCDClient, MnemonicKey, MsgCreate, Wallet, /* MsgCreate2 */ } from '@initia/initia.js';
import * as fs from 'fs';
import dotenv from 'dotenv';
dotenv.config();
async function main() {

    const lcdURL = process.env.LCD_URL!;
    const gasPrices = process.env.GAS_PRICES;
    const chainId = process.env.CHAIN_ID;
    
    const gasAdjustment = process.env.GAS_ADJUSTMENT;
    console.log(lcdURL)
    const lcd = new LCDClient(lcdURL, {
        gasPrices: gasPrices,
        chainId: chainId,
        gasAdjustment: gasAdjustment,
      });
    
      const key = new MnemonicKey({
        mnemonic:
          'sudden puzzle despair repair spirit tone next toast topple bring fashion adjust floor usual canyon pass forum decrease between soft lottery quiz across edge',
      });
      const wallet = new Wallet(lcd, key);
      const path = './build/Test.bin';
      const codeBytes = fs.readFileSync(path, "utf-8");
      const msgs = [
        new MsgCreate(key.accAddress, codeBytes),
        // new MsgCreate2(key.accAddress, codeBytes, slat)
      ];
    
      // sign tx
      const signedTx = await wallet.createAndSignTx({ msgs
        
       });
    //   // send(broadcast) tx
      lcd.tx.broadcastSync(signedTx).then(res => console.log(res));

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});