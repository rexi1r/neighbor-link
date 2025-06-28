var toastShowCount = 0;
var isSet=false
const buildVersionLabel = document.getElementById('build-version')
function heartBeat() {
    const Device_ID=["uci", "get", {"config":"routro"}];
    ubus_call(Device_ID,function(chunk){
        if(chunk[0] !== 0) {
            M.toast({html: "You're not connected to router!", classes: 'red'});
            toastShowCount++
        } 
        else if(chunk[1]?.values?.firmware?.version){
            const currentVersion = chunk[1].values.firmware.version
            if(buildVersionLabel){
                buildVersionLabel.textContent = `Build version ${currentVersion}`
            }
            if(isSet==false){
                const versionSeen = localStorage.getItem("opr-version-seen");
                if(currentVersion != versionSeen){
                    localStorage.setItem("opr-dashboard-seen","false")
                }
                localStorage.setItem("opr-version-seen", currentVersion);
                isSet=true;
            }
        }
        if(toastShowCount >= 3) {
            window.location.href = "index.html"
        }
    }, true);
}

setInterval(() => {
    heartBeat()
}, 5000);
