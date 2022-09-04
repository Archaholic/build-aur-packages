#!/usr/bin/env bash

# fail if anything goes wrong
set -e
# print each line before executing
set -x

# Get list of all packages with dependencies to install.
packages_with_aur_dependencies="$(aur depends --pkgname $INPUT_PACKAGES $INPUT_MISSING_AUR_DEPENDENCIES)"
echo "AUR Packages requested to install: $INPUT_PACKAGES"
echo "AUR Packages to fix missing dependencies: $INPUT_MISSING_AUR_DEPENDENCIES"
echo "AUR Packages to install (including dependencies): $packages_with_aur_dependencies"

# sync repositories
pacman -Sy

if [ -n "$INPUT_MISSING_PACMAN_DEPENDENCIES" ]
then
    echo "Additional Pacman packages to install: $INPUT_MISSING_PACMAN_DEPENDENCIES"
    pacman --noconfirm -S $INPUT_MISSING_PACMAN_DEPENDENCIES
fi

# Add the packages to the local repository.
sudo --user builder \
    aur sync \
    --noconfirm --noview \
    --database TheRepoClub-v1 --root /home/builder/workspace \
    $packages_with_aur_dependencies

# Move the local repository to the workspace.
if [ -n "$GITHUB_WORKSPACE" ]
then
    rm -f /home/builder/workspace/*.old
    echo "Moving repository to github workspace"
    mv /home/builder/workspace/* $GITHUB_WORKSPACE/
    # make sure that the .db/.files files are in place
    # Note: Symlinks fail to upload, so copy those files
    cd $GITHUB_WORKSPACE
    rm TheRepoClub-v1.db TheRepoClub-v1.files
    cp TheRepoClub-v1.db.tar.gz TheRepoClub-v1.db
    cp TheRepoClub-v1.files.tar.gz TheRepoClub-v1.files
else
    echo "No github workspace known (GITHUB_WORKSPACE is unset)."
fi
