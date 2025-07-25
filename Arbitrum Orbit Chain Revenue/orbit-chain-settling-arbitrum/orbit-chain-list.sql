SELECT
  chain_name,
  sequencerInbox_address
FROM (VALUES
  ('Sanko', 0x24b68936c13a414cd91437ae7aa730321b9ff159),
  ('Superposition', 0xe0064a9fb8e45bfd8e5ab1ce7523888814a096e0),
  ('Deri Chain', 0xe347c1223381b9dcd6c0f61cf81c90175a7bae77),
  ('Molten Network', 0x0ffe9acc296ddd4de5f616aa482c99fa4b41a3e2),
  ('WINR', 0x8aedde55cb361e73a0b0c0cf2a5bb35e97a20456),
  ('Blessnet', 0x1e751242c9ce10e165969eed91e5d98587904aad),
  ('RARI Chain', 0xa436f1867add490bf1530c636f2fb090758bb6b3),
  ('EDU Chain', 0xa3464bf0ed52cfe6676d3e34ab1f4df53f193631),
  ('Proof of Play Apex', 0xa58f38102579dae7c584850780dda55744f67df1),
  ('Proof of Play Boss', 0x6ee94ad8057fd7ba4d47bb6278a261c8a9fd4e3f),
  ('ApeChain', 0xe6a92ae29e24c343ee66a2b3d3ecb783d65e4a3c),
  ('Xai', 0x995a9d3ca121d48d21087ede20bc8acb2398c8b1)
) AS t(chain_name, sequencerInbox_address)