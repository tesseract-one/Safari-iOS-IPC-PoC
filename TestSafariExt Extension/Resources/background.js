browser.runtime.onMessage.addListener(async (request, sender) => {
    if (request.to !== "native") {
        return { error: "unsupported request" };
    }
    try {
        let response = await browser.runtime.sendNativeMessage("application.id", request);
        return { response: response };
    } catch(error) {
        return { error: error.toString() };
    }
});
