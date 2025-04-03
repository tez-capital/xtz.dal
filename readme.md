## xtz.dal
Tezos Dal Node Package

### Setup

1. If not already installed, install ami:
```sh
wget -q https://raw.githubusercontent.com/alis-is/ami/master/install.sh -O /tmp/install.sh && sh /tmp/install.sh
```
2. Create a directory for your application. It should not be part of user home folder structure. For example, you can use `/mns/xtz1`.
3. Create app.json or app.hjson with the configuration you prefer.
Sample configuration:
```hjson
{
    id: dal-node
    type: xtz.dal
    configuration: {
        NODE_ENDPOINT: <node endpoint> # e.g. http://127.0.0.1:8732
        ATTESTER_PROFILES: [
            <attester1> # e.g. tz1...
        ]
        "CONFIG_FILE": { 
            # ...
        }
    }
    user: xtznode
}
```
`CONFIG_FILE` is content of dal node configuration.

4. Run `ami --path=<your app path> setup`, for example, `ami --path=/mns/xtz1 setup`. 
	- run `ami --path=<your app path> --help` to see available commands.
5. Start your dal node with `ami --path=<your app path> start`.
6. Check the dal node's info with `ami --path=<your app path> info`.

NOTE: trusted setup is not required for attester profiles. Because of that trusted setup is **NOT** installed by default. You can install it with `ami --path=<your app path> install-trusted-setup`

### Configuration Change

1. Stop the app: `ami --path=<your app path> stop`.
2. Change `app.json` or `app.hjson` as required.
3. Reconfigure the setup: `ami --path=<your app path> setup --configure`.
4. Restart the app: `ami --path=<your app path> start`.

### Removing the App

1. Stop the app: `ami --path=<your app path> stop`.
2. Remove the app: `ami --path=<your app path> remove --all`.

### Reset dal node

1. Stop the app: `ami --path=<your app path> stop`.
2. Remove the app: `ami --path=<your app path> remove --chain`.
3. (optional) bootstrap the app with `ami --path=<your app path> bootstrap <url> <block hash>`
4. Restart the app: `ami --path=<your app path> start`.

### Troubleshooting

To enable trace level printout, run `ami` with `-ll=trace`. For example: `ami --path=/mns/xtz1 -ll=trace setup`.

Remember to adjust the path according to your app's location.


### Updating sources

Sources can be updated with:
`eli src/__xtz/update-sources.lua https://gitlab.com/tezos/tezos/-/packages/25835249`