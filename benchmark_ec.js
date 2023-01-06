const EC = require('elliptic').ec;
// Create a new elliptic curve object
const ec = new EC('secp256k1');
const secp = require('noble-secp256k1');
const { randomBytes } = require('crypto');

const generatorPoint = ec.g;
const p_scan = "d952fe0740d9d14011fc8ead3ab7de3c739d3aa93ce9254c10b0134d80d26a30";

const P_elliptic = generatorPoint.mul(p_scan);
const P_noble = secp.Point.fromPrivateKey(p_scan);

const numRuns = 1000;

// We generate random private keys for elliptic, then use those to generate
// the same random private keys for noble-secp256k1. This way we have the same
// private keys being used for each, already in the required format to avoid
// benchmarking any overhead from converting the private key formats. We use
// a different private key in each iteration of the below for loops to avoid
// JIT optimizations that might occur if the same private key is used each time.
function getRandomPrivateKeysElliptic() {
  return Array.from(Array(numRuns)).map(_ => randomBytes(32))
}
function getRandomPrivateKeysNoble(ellipticPrivateKeys) {
  return ellipticPrivateKeys.map(key => BigInt(`0x${key.toString('hex')}`))
}

// Similar for the points (public keys) derived from those private keys.
function getPointsElliptic(privateKeys) {
  return privateKeys.map(key => generatorPoint.mul(key))
}
function getPointsNoble(privateKeys) {
  return privateKeys.map(key => secp.Point.fromPrivateKey(key))
}

// Setup the test data.
const ellipticPrivateKeys = getRandomPrivateKeysElliptic();
const ellipticPoints = getPointsElliptic(ellipticPrivateKeys);
const noblePrivateKeys = getRandomPrivateKeysNoble(ellipticPrivateKeys);
const noblePoints = getPointsNoble(noblePrivateKeys);
let startTime, endTime, deltaTime;

// -------------------------------------
// -------- Elliptic Benchmarks --------
// -------------------------------------
console.log("elliptic.js:");

// --- Private Key to Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan = generatorPoint.mul(ellipticPrivateKeys[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x privKey --> pubKey: ${deltaTime} milliseconds`);

// --- Private Key * Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan =  P_elliptic.mul(ellipticPrivateKeys[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x privKey * pubKey: ${deltaTime} milliseconds`);

// --- Public Key + Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan = P_elliptic.add(ellipticPoints[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x pubKey + pubKey: ${deltaTime} milliseconds`);

console.log("-----------------------------------------");

// --------------------------------------------
// -------- noble-secp256k1 Benchmarks --------
// --------------------------------------------
console.log("noble-secp256k1.js:");

// --- Private Key to Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan =  secp.getPublicKey(noblePrivateKeys[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x privKey --> pubKey: ${deltaTime} milliseconds`);

// --- Private Key * Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan = secp.getSharedSecret(noblePrivateKeys[k], P_noble);
  // const P_scan = P_noble.multiply(noblePrivateKeys[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x privKey * pubKey: ${deltaTime} milliseconds`);

// --- Public Key + Public Key ---
startTime = performance.now()
for (let k = 0; k < numRuns; k++) {
  const P_scan = P_noble.add(noblePoints[k]);
}
endTime = performance.now()
deltaTime = endTime - startTime;
console.log(`1000x pubKey + pubKey: ${deltaTime} milliseconds`);
