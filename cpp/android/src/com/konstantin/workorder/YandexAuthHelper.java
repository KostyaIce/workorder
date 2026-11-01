package com.konstantin.workorder;

import android.app.Activity;
import android.content.Intent;

import com.yandex.authsdk.YandexAuthLoginOptions;
import com.yandex.authsdk.YandexAuthOptions;
import com.yandex.authsdk.YandexAuthResult;
import com.yandex.authsdk.YandexAuthSdk;
import com.yandex.authsdk.YandexAuthSdkContract;
import com.yandex.authsdk.YandexAuthToken;

public final class YandexAuthHelper
{
    public static final int REQUEST_CODE = 0x5941;

    private static YandexAuthSdk sdk;
    private static YandexAuthSdkContract contract;

    private YandexAuthHelper()
    {
    }

    public static void start(Activity activity)
    {
        sdk = YandexAuthSdk.create(new YandexAuthOptions(activity));
        contract = sdk.getContract();
        final Intent intent = contract.createIntent(activity, new YandexAuthLoginOptions());
        activity.startActivityForResult(intent, REQUEST_CODE);
    }

    public static String finish(int requestCode, int resultCode, Intent data)
    {
        if(requestCode != REQUEST_CODE)
            return null;
        if(contract == null)
            return "ERROR:Yandex Auth SDK contract is not initialized";

        try
        {
            final YandexAuthResult result = contract.parseResult(resultCode, data);
            if(result instanceof YandexAuthResult.Success)
            {
                final YandexAuthToken token = ((YandexAuthResult.Success) result).getToken();
                return "OK:" + token.getValue();
            }
            if(result instanceof YandexAuthResult.Failure)
            {
                final Exception error = ((YandexAuthResult.Failure) result).getException();
                return "ERROR:" + (error != null ? error.getMessage() : "unknown error");
            }
            return "CANCELLED";
        }
        catch(Exception error)
        {
            return "ERROR:" + error.getMessage();
        }
    }
}
