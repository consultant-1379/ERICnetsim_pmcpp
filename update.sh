#!/bin/sh

RPM=$1

scp ${RPM} root@atrclin3.athtem.eei.ericsson.se:/var/repo/systemtest/release
ssh root@atrclin3.athtem.eei.ericsson.se /usr/bin/createrepo --update /var/repo/systemtest/release
ssh root@atrclin3.athtem.eei.ericsson.se /usr/bin/gpg --batch --yes --detach-sign --armor --passphrase-file /var/repo/systemtest/input /var/repo/systemtest/release/repodata/repomd.xml
