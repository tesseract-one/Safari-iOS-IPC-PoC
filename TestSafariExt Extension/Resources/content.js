async function nativeRequest(method, params) {
    let response = await browser.runtime.sendMessage({
        id: null, to: "native", method: method, params: params
    });
    if (response.error) {
        throw new Error(response.error)
    }
    return response.response;
}

function sendResponse(id, method, res, error) {
    const message = {id: id, method: method, to: "page"};
    if (error) {
        message.error = error;
    } else {
        message.response = res;
    }
    window.postMessage(message, "*");
}

function sendResponseMessage(id, promise, method) {
    if (!method) { method = "WALLET_RESPONSE" }
    promise.then((res) => {
        sendResponse(id, method, res);
    }).catch((err) => {
        sendResponse(id, method, null, err.toString());
    });
}

window.addEventListener("message", (event) => {
    // We only accept messages from ourselves
    if (event.source !== window) { return; }
    if (event.data.to !== "ALLWALLETS" && event.data.to !== browser.runtime.id) { return; }
    if (!event.data.method) {
        console.error("Bad event", event);
        return;
    }
    if (event.data.method === "WALLET_EXTENSION_INFO_REQUEST") {
        const promise = nativeRequest("info", [])
            .then((res) => {
                res.id = browser.runtime.id;
                return res;
            });
        sendResponseMessage(event.data.id,
                            promise,
                            "WALLET_EXTENSION_INFO_RESPONSE");
        return;
    }
    if (!event.data.id) {
        console.error("No id", event.data);
        return;
    }
    if (typeof event.data.params !== "array"
        && event.data.params.length !== 1) {
        sendResponse(event.data.id, "WALLET_RESPONSE",
                     null, "Wrong params. Expected Array(1)")
        return;
    }
    switch (event.data.method) {
        case "WALLET_REQUEST_WRITE":
            sendResponseMessage(event.data.id,
                                nativeRequest("send", [event.data.params[0]]));
            break;
        case "WALLET_RESPONSE_READ":
            sendResponseMessage(event.data.id,
                                nativeRequest("receive", [event.data.params[0]]));
            break;
        case "WALLET_REQUEST_CANCEL":
            sendResponseMessage(event.data.id,
                                nativeRequest("clean", [event.data.params[0]]));
            break;
        default:
            sendResponse(event.data.id, "WALLET_RESPONSE",
                         null, "Unsupported method: " + event.data.method);
            break;
    }
}, false);
