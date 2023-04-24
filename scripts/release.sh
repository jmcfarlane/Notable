#!/bin/bash -eu

cd $(dirname $0)/..

arms=(6 7)
systems=(darwin freebsd linux windows)

# The date is something like: 2017-01-20
export DATE="$(head -n1 CHANGELOG.md | grep -E -o '[0-9]{4}-[0-9]{2}-[0-9]{2}')"

# Find the Second file heading (because the first heading is removed,
# the resulting offset is then adjusted by 1 line).
offset=$(tail -n +2 CHANGELOG.md | grep -n '^## ' | head -n1 | grep -E -o '^[0-9]+')
offset=$((offset-1))

# Extract the description from this release as the "inner" first
# section of the changelog.
DESC=$(sed -n "3,${offset}p" CHANGELOG.md)

# Create and push git tags
git tag -a $TAG -m "Release on $DATE"
git push --tags

# Create the release itself
github-release release \
    --user jmcfarlane \
    --repo notable \
    --tag $TAG \
    --name "$TAG / $DATE" \
    --description "$DESC" \
    --pre-release

# Uploads for amd64
for goos in ${systems[@]}; do
    github-release upload \
        --user jmcfarlane \
        --repo notable \
        --tag $TAG \
        --name "notable-${TAG}.${goos}-amd64.zip" \
        --file target/notable-${TAG}.${goos}-amd64.zip
    echo "Uploaded: target/notable-${TAG}.${goos}-amd64.zip"
done

# Uploads for arm
for v in ${arms[@]}; do
    github-release upload \
        --user jmcfarlane \
        --repo notable \
        --tag $TAG \
        --name "notable-${TAG}.linux-arm${v}.zip" \
        --file target/notable-${TAG}.linux-arm${v}.zip
    echo "Uploaded: target/notable-${TAG}.linux-arm${v}.zip"
done

# Tag for release
docker tag github.com/jmcfarlane/notable:latest jmcfarlane/notable:latest
docker tag github.com/jmcfarlane/notable:$TAG jmcfarlane/notable:$TAG

# Publish
docker login docker.io
docker push jmcfarlane/notable:latest
docker push jmcfarlane/notable:$TAG
