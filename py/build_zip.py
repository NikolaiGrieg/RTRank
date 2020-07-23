from zipfile import ZipFile
import os
from os.path import basename

from rootfile import ROOT_DIR


# Adapted from: https://thispointer.com/python-how-to-create-a-zip-archive-from-multiple-files-or-directory/
def zipFilesInDir(dirName, zipFileName, filter):
    # create a ZipFile object
    with ZipFile(zipFileName, 'w') as zipObj:
        # Iterate over all the files in directory
        for folderName, subfolders, filenames in os.walk(dirName):
            for filename in filenames:
                # todo might need a blacklist instead of single item
                if filter(filename) and "tmp" not in os.path.join(folderName, filename):
                    # create complete filepath of file in directory
                    filePath = os.path.join(folderName, filename)

                    # Add file to zip
                    folder_base = basename(folderName)
                    if folder_base == "RTRank":  # Only supports 1 folder level
                        rel_path = "RTRank" + "\\" + basename(filePath)
                    else:
                        rel_path = "RTRank" + "\\" + folder_base + "\\" + basename(filePath)
                    print(f"Added {rel_path}")
                    zipObj.write(filePath, rel_path)


def include_filter(filename):
    whitelist = [".lua", "RTRank.toc", "LICENSE", "README.md"]
    for item in whitelist:
        if item in filename:
            return True
    return False


if __name__ == "__main__":
    zipFilesInDir(ROOT_DIR, ROOT_DIR + "\\build\\RTRank_Alpha3.zip", include_filter)
