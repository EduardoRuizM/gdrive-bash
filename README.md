<p align="center">
  <a href="https://github.com/EduardoRuizM/gdrive-bash"><img src="logo.png" title="Google Drive Client (Bash)" width="640" height="100"></a>
</p><h1 align="center">Google Drive Client
  <a href="https://github.com/EduardoRuizM/gdrive-bash">EduardoRuizM/gdrive-bash</a>
</h1>
<p align="center">Dataclick <a href="https://github.com/EduardoRuizM/gdrive-bash">Google Drive Client (Bash)</a>
</p>

# [Google Drive Client v3 (Bash)](https://github.com/EduardoRuizM/gdrive-bash "Google Drive Client v3 (Bash)")

![Bash](https://img.shields.io/badge/Bash-30363C?logo=gnubash&logoColor=fff) ![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

✔️ Full Google Drive client with multi-account support.

✔️ Supports all types of operations: list files and folders with name search, quota, upload, download, move, rename, create folder, delete, send to trash.

✔️ Lightweight with no dependencies, fast and portable (9 KB).

✔️ Pure Bash scripting on Linux.

✔️ Internal implementation of the OAuth 2.0 (Open Authorization) protocol for authenticating and authorizing access to Google services.

✔️ Google Drive API v3 support for enhanced performance, security, and simplified file management.

# Author
[Eduardo Ruiz](https://github.com/EduardoRuizM) <<eruiz@dataclick.es>>

# ⚙ Create your APP
1. Go to Google Cloud Console: [https://console.cloud.google.com](https://console.cloud.google.com)

2. Create a new project in the top bar, select **New Project**, enter a name, and click **Create**.

3. Enable Google Drive API, search for **Google Drive API** and click **Enable**.

4. Go to Credentials in the left menu, go to **APIs & Services** > **Credentials**.

5. Click **Configure Consent Screen**, select **External**, and fill in the required fields (App name, Support email, and Developer contact). Click **Save and Continue**.

6. Click **Add or Remove Scopes**, select these two:
   - `.../auth/drive`
   - `.../auth/drive.metadata.readonly`
   Then click **Update**

7. Create OAuth credentials
   Go back to **Credentials**, click **Create Credentials**, and select **OAuth client ID**.

8. Choose application type
   Select **Desktop App**, give it a name, and click **Create**.

9. Set Redirect URI
   In the OAuth client configuration, under **Authorized redirect URIs**, add `http://localhost`

10. Copy the **Client ID** and **Client Secret** that appear. Click **OK**.

11. Publish the app to prevent token expiration, go to **OAuth consent screen** and click **Publish App**.

# Installation
- Copy **gdrive.sh** to `/usr/local/bin`
- Grant execute permission with `chmod +x /usr/local/bin/gdrive.sh`
- Create a folder for account data files with `mkdir -p /etc/gdrive/accounts`
  You can change this path, but modifying the line `ACCOUNT_PATH="/etc/gdrive/accounts"` in **gdrive.sh**

# Manage Accounts
- To allow the management of multiple separate accounts.
- Please use only letters and numbers por the ACCOUNT name.
- A single file is created in ACCOUNT_PATH containing the credentials and variables for account management.

| Command | Parameters | Action | Sample |
| --- | --- | --- | --- |
| **list** | - | Show all accounts | ./gdrive.sh list |
| **create** | -account {ACCOUNT} -client {CLIENT} -secret {SECRET}<br><br>client and secret are optional or alternatively they can be requested from the console | Create a new account file | ./gdrive.sh create -account myaccount |
| **remove** | -account {ACCOUNT} | Delete account | ./gdrive.sh delete myaccount |

# Google Drive Commands
- You must specify the account created in the previous step with the **-account** parameter.
- In many commands, the working folder is specified using the optional **-parent** parameter, which indicates an alphanumeric ID obtained from the listings, or *root* folder if not specified.
- The **-search** parameter is optional and can be used to search for names containing this text.
- Responses are in JSON format, to process them, you can use https://jqlang.github.io/jq

| Command | Parameters | Action | Sample |
| --- | --- | --- | --- |
| **init** | -account {ACCOUNT} | Initialize it for the first time, then paste returned URL in the browser | ./gdrive.sh init -account myaccount |
| **quota** | -account {ACCOUNT} | Show limit and usage in MB | ./gdrive.sh quota -account myaccount |
| **folders** | -account {ACCOUNT} -search {STRING} -parent {ID_FOLDER} | Show folders, optional search name contains STRING and optional -parent folder | ./gdrive.sh folders -account myaccount |
| **files** | -account {ACCOUNT} -search {STRING} -parent {ID_FOLDER} | Show files, optional search name contains STRING and optional -parent folder | ./gdrive.sh files -account myaccount |
| **upload** | -account {ACCOUNT} -file {FILE} -parent {ID_FOLDER} | Upload file FILE in optional ID_FOLDER | ./gdrive.sh upload -account myaccount -file mylocalfile.doc -parent xxxxxx |
| **download** | -account {ACCOUNT} -id {ID} -file {FILE} | Download ID file into FILE | ./gdrive.sh download -account myaccount -id yyyyy -file mylocalfile.doc |
| **move** | -account {ACCOUNT} -id {ID} -parent {ID_FOLDER} -from {ID_FROM} | Move ID file to ID_FOLDER folder from ID_FROM folder<br><br>If parent or from are not specified, the root folder will be used | ./gdrive.sh move -account myaccount -id yyyyy -parent xxxxxx |
| **rename** | -account {ACCOUNT} -id {ID} -name {NAME} | Rename ID file to NAME | ./gdrive.sh rename -account myaccount -id yyyyy -name "myremotefile.doc" |
| **md** | -account {ACCOUNT} -name {NAME} -parent {ID_FOLDER} | Create folder name, optional -parent folder | ./gdrive.sh md -account myaccount -name "myfolder" |
| **delete** | -account {ACCOUNT} -id {ID} | Delete ID file | ./gdrive.sh delete -account myaccount -id yyyyy |
| **trash** | -account {ACCOUNT} -id {ID} | Send to trash ID file | ./gdrive.sh trash -account myaccount -id yyyyy |

# Trademarks©️
- [Dataclick.es](https://www.dataclick.es "Dataclick.es") is a software development company since 2006.
- [Olimpo](https://www.dataclick.es/en/technology-behind-olimpo.html "Olimpo") is a whole solution software to manage all domains services such as hosting services and to create Webs in a server.
- JuNe / JUst NEeded Philosophy, available software and development solutions.
- [Google Drive Client](https://github.com/EduardoRuizM/gdrive-bash "Google Drive Client") is a part of Dataclick Olimpo domains management service, released to Internet community.
- Feel free to use this software according MIT license respecting the brand and image logotype that you can use.

# MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
