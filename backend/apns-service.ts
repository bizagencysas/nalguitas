import * as crypto from "node:crypto";
import * as http2 from "node:http2";
import * as fs from "node:fs";
import * as path from "node:path";

const TEAM_ID = "7KG6CT3HX5";
const KEY_ID = "4LHKNF3PAH";
const BUNDLE_ID = "app.rork.amor-rosa-app";
const APNS_HOST = "api.push.apple.com";

let cachedKey: string | null = null;
let cachedToken: string | null = null;
let tokenIssuedAt = 0;

function getSigningKey(): string {
  if (cachedKey) return cachedKey;
  const keyPath = path.join(import.meta.dir, "AuthKey_4LHKNF3PAH.p8");
  cachedKey = fs.readFileSync(keyPath, "utf8");
  return cachedKey;
}

function base64url(data: Buffer | string): string {
  const buf = typeof data === "string" ? Buffer.from(data) : data;
  return buf.toString("base64url");
}

function generateJWT(): string {
  const now = Math.floor(Date.now() / 1000);

  if (cachedToken && now - tokenIssuedAt < 3000) {
    return cachedToken;
  }

  const header = base64url(JSON.stringify({ alg: "ES256", kid: KEY_ID }));
  const payload = base64url(JSON.stringify({ iss: TEAM_ID, iat: now }));
  const signingInput = `${header}.${payload}`;

  const key = getSigningKey();
  const sign = crypto.createSign("SHA256");
  sign.update(signingInput);
  const derSig = sign.sign(key);

  const r = extractR(derSig);
  const s = extractS(derSig);
  const rawSig = Buffer.concat([padTo32(r), padTo32(s)]);
  const signature = base64url(rawSig);

  cachedToken = `${signingInput}.${signature}`;
  tokenIssuedAt = now;
  return cachedToken;
}

function extractR(der: Buffer): Buffer {
  let offset = 3;
  const rLen = der[offset];
  offset += 1;
  return der.subarray(offset, offset + rLen);
}

function extractS(der: Buffer): Buffer {
  let offset = 3;
  const rLen = der[offset];
  offset += 1 + rLen + 1;
  const sLen = der[offset];
  offset += 1;
  return der.subarray(offset, offset + sLen);
}

function padTo32(buf: Buffer): Buffer {
  if (buf.length === 33 && buf[0] === 0) {
    return buf.subarray(1);
  }
  if (buf.length === 32) return buf;
  if (buf.length < 32) {
    const padded = Buffer.alloc(32);
    buf.copy(padded, 32 - buf.length);
    return padded;
  }
  return buf.subarray(buf.length - 32);
}

export async function sendPushNotification(
  deviceToken: string,
  title: string,
  body: string,
  sound: string = "default"
): Promise<{ success: boolean; statusCode?: number; error?: string }> {
  return new Promise((resolve) => {
    try {
      const jwt = generateJWT();

      const client = http2.connect(`https://${APNS_HOST}`);

      client.on("error", (err) => {
        console.error("APNs connection error:", err.message);
        resolve({ success: false, error: err.message });
      });

      const payload = JSON.stringify({
        aps: {
          alert: { title, body },
          sound,
          badge: 1,
        },
      });

      const req = client.request({
        ":method": "POST",
        ":path": `/3/device/${deviceToken}`,
        authorization: `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
        "content-length": Buffer.byteLength(payload),
      });

      let responseData = "";
      let statusCode = 0;

      req.on("response", (headers) => {
        statusCode = headers[":status"] as number;
      });

      req.on("data", (chunk: Buffer) => {
        responseData += chunk.toString();
      });

      req.on("end", () => {
        client.close();
        if (statusCode === 200) {
          resolve({ success: true, statusCode });
        } else {
          console.error("APNs error:", statusCode, responseData);
          resolve({
            success: false,
            statusCode,
            error: responseData || `Status ${statusCode}`,
          });
        }
      });

      req.on("error", (err) => {
        client.close();
        resolve({ success: false, error: err.message });
      });

      req.write(payload);
      req.end();

      setTimeout(() => {
        try { client.close(); } catch {}
        resolve({ success: false, error: "Timeout" });
      }, 15000);
    } catch (err: any) {
      console.error("APNs send error:", err.message);
      resolve({ success: false, error: err.message });
    }
  });
}
