var guestSsid = document.getElementById('wifi-ssid');
var guestPassword = document.getElementById('wifi-password');
var guestUpdate = document.getElementById('wifi-update');
var routingModeSelect = document.getElementById('routing-mode');

const killSwitchEnable = document.getElementById('kill-switch-enable');
const killSwitchLabel = document.getElementById('kill-switch-enable-label');
const guestBlockEnable = document.getElementById('guest-block-enable');
const guestBlockLabel = document.getElementById('guest-block-enable-label');



function validateSSID(ssid) {
    // Allowed characters: alphanumeric, space, and special characters ! . _ - ()
    const ssidRegex = /^[a-zA-Z0-9 !._\-()]+$/;
    return ssidRegex.test(ssid);
}

function validatePassword(password) {
    // Allowed characters: any printable ASCII character
    const passwordRegex = /^[\x20-\x7E]+$/; // ASCII range for printable characters (space to ~)
    return passwordRegex.test(password);
}

guestUpdate.onclick = async function(e){
    var newSSID = guestSsid.value;
    var newPASS = guestPassword.value;
    if( !validateSSID(newSSID) ){
        addCustomAlert("Error!","SSID has not acceptable charachter",5000)
        return
    }
    if( !validatePassword(newPASS) ){
        addCustomAlert("Error!","Password has not acceptable charachter",5000)
        return
    }
    if( newPASS.length < 8 ){
        addCustomAlert("Error!","Password must be at leaset 8 charachters",5000)
        return
    }

    loading(true,"Set Wifi Info")
    await async_lua_call("dragon.sh","wifi-set "+newSSID+" "+newPASS)
    await wifiInfo()
}


wifiInfo()
async function wifiInfo(){
    loading(true)
    const WIFI_INFO=["uci", "get", {"config":"wireless"}];
    var info = await async_ubus_call(WIFI_INFO);
    var device_wifi_info  = info[1].values
    var guest_wifi_2g = device_wifi_info["default_radio1"]

    if(guest_wifi_2g && guest_wifi_2g.disabled == "0"){
        guestSsid.value = removeSubstring(guest_wifi_2g["ssid"],"-2g")
        guestPassword.value =  guest_wifi_2g["key"]
        loading(false)
        return
    }

    var guest_wifi_5g = device_wifi_info["default_radio0"]
    if(guest_wifi_5g && guest_wifi_5g.disabled == "0"){
        guestSsid.value = removeSubstring(guest_wifi_5g["ssid"],"-5g")
        guestPassword.value =  guest_wifi_5g["key"]
        loading(false)
        return
    }

    loading(false)
    return
}

loadRoutingMode();

async function loadRoutingMode(){
    const CONFIG_INFO=["uci","get",{"config":"routro"}];
    var info = await async_ubus_call(CONFIG_INFO);
    if(info && info[1] && info[1].values && info[1].values.routing){
        routingModeSelect.value = info[1].values.routing.mode;
    }
}

routingModeSelect.onchange = async function(e){
    var mode = routingModeSelect.value;
    await async_lua_call("dragon.sh","routing-mode "+mode);
}

killSwitchEnable.onclick = async function(e){
    setKillSwitchStatus(killSwitchEnable.checked)
    if(killSwitchEnable.checked){
        loading(true,"Enabling kill switch")
        await async_lua_call("dragon.sh","killswitch-on")
    }else{
        loading(true,"Disabling kill switch")
        await async_lua_call("dragon.sh","killswitch-off")
    }
    await readKillSwitchStatus()
    loading(false)

}

guestBlockEnable.onclick = async function(e){
    setGuestBlockStatus(guestBlockEnable.checked)
    if(guestBlockEnable.checked){
        loading(true,"Blocking guest access")
        await async_lua_call("dragon.sh","guest-mgmt-block-on")
    }else{
        loading(true,"Allowing guest access")
        await async_lua_call("dragon.sh","guest-mgmt-block-off")
    }
    await readGuestBlockStatus()
    loading(false)

}

function setGuestBlockStatus(status){
    if(status){
        guestBlockLabel.textContent = "Enable";
        guestBlockEnable.checked = true;
    }else{
        guestBlockLabel.textContent = "Disable";
        guestBlockEnable.checked = false;
    }
}

async function readGuestBlockStatus(){
    const GB_STAT=["file","exec",{"command":"dragon.sh","params":[ "guest-mgmt-block-status" ]}];
    var response=await async_ubus_call(GB_STAT);
    const stdout = response[1].stdout;
    if(stdout.includes('0')){
        setGuestBlockStatus(false);
    }else{
        setGuestBlockStatus(true);
    }
    loading(false);
}

function setKillSwitchStatus(status){
    if(status){
        killSwitchLabel.textContent = "Enable";
        killSwitchEnable.checked = true;
    }else{
        killSwitchLabel.textContent = "Disable";
        killSwitchEnable.checked = false;
    }
}

async function readKillSwitchStatus(){
    const KS_STAT=["file","exec",{"command":"dragon.sh","params":[ "killswitch-status" ]}];
    var response=await async_ubus_call(KS_STAT);
    const stdout = response[1].stdout;
    if(stdout.includes('0')){
        setKillSwitchStatus(false);
    }else{
        setKillSwitchStatus(true);
    }
    loading(false);
}

readKillSwitchStatus();
readGuestBlockStatus();
