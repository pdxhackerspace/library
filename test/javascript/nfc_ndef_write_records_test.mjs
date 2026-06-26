import test from 'node:test'
import assert from 'node:assert/strict'
import { buildNdefWriteRecords } from '../../app/javascript/nfc/ndef_write_records.mjs'

test('URL record keeps string data', () => {
  const url = 'https://library.example.com/books/1'
  const records = buildNdefWriteRecords(url, '{"title":"Test"}')

  assert.equal(records[0].recordType, 'url')
  assert.equal(records[0].data, url)
})

test('MIME record encodes JSON as Uint8Array for Web NFC', () => {
  const json = '{"isbn":"123","title":"Test"}'
  const records = buildNdefWriteRecords('https://library.example.com/books/1', json)

  assert.equal(records[1].recordType, 'mime')
  assert.equal(records[1].mediaType, 'application/json')
  assert.ok(records[1].data instanceof Uint8Array, 'mime record data must be a BufferSource')
  assert.equal(new TextDecoder().decode(records[1].data), json)
})
