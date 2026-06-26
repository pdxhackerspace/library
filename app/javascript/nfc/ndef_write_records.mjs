export function buildNdefWriteRecords(url, json) {
  const encoder = new TextEncoder()

  return [
    { recordType: 'url', data: url },
    { recordType: 'mime', mediaType: 'application/json', data: encoder.encode(json) }
  ]
}
