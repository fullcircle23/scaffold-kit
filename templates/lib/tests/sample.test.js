import assert from "node:assert/strict";
import { hello } from "../dist/index.js";
assert.equal(hello("Ravi"), "Hello, Ravi!");
