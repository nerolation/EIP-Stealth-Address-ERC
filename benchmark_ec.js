const EC = require('elliptic').ec;
const keccak256 = require('js-sha3').keccak256;
// Create a new elliptic curve object
const ec = new EC('secp256k1');
const secp = require('noble-secp256k1');

const { performance } = require('perf_hooks');

const generatorPoint = ec.g;
const p_scan = "d952fe0740d9d14011fc8ead3ab7de3c739d3aa93ce9254c10b0134d80d26a30";

const P1 = generatorPoint.mul(p_scan);
const P2 = secp.getPublicKey(p_scan);

const numRuns = 1000;


console.log("elliptic.js:");
for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan = generatorPoint.mul(p_scan);
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x privKey --> pubKey: ${deltaTime} milliseconds`);
}


for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan =  P1.mul(p_scan);
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x privKey * pubKey: ${deltaTime} milliseconds`);
}



for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan = P1.add(P1);
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x pubKey + pubKey: ${deltaTime} milliseconds`);
}
console.log("-----------------------------------------");


console.log("noble-secp256k1.js:");
for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan =  secp.getPublicKey(p_scan);
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x privKey --> pubKey: ${deltaTime} milliseconds`);
}



for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan = secp.getSharedSecret(Buffer.from(p_scan, 'hex'), P2);
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x privKey * pubKey: ${deltaTime} milliseconds`);
}


for (let j = 0; j < 1; j++) {
  const startTime = performance.now()
  for (let k = 0; k < numRuns; k++) {
    const P_scan = secp.Point.fromHex(P2).add(secp.Point.fromHex(P2));
  }
  const endTime = performance.now()
  const deltaTime = endTime - startTime;
  console.log(`1000x pubKey + pubKey: ${deltaTime} milliseconds`);
}
