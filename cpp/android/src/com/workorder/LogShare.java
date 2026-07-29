package com.workorder;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import androidx.core.content.FileProvider;

import java.io.File;

/**
 * Share a zip of app logs via the system chooser (same pattern as KelVPN sendLogs).
 */
public final class LogShare
{
    private static final String TAG = "WorkOrderLogShare";

    private LogShare()
    {
    }

    public static boolean shareZip(Context context, String zipPath)
    {
        if(context == null || zipPath == null || zipPath.isEmpty())
        {
            Log.e(TAG, "shareZip: invalid arguments");
            return false;
        }

        final File zipFile = new File(zipPath);
        if(!zipFile.exists() || !zipFile.isFile())
        {
            Log.e(TAG, "shareZip: file missing: " + zipPath);
            return false;
        }

        try
        {
            final String authority = context.getPackageName() + ".qtprovider";
            final Uri uri = FileProvider.getUriForFile(context, authority, zipFile);

            final Intent sendIntent = new Intent(Intent.ACTION_SEND);
            sendIntent.putExtra(Intent.EXTRA_STREAM, uri);
            sendIntent.setType("application/zip");
            sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

            final Intent chooser = Intent.createChooser(sendIntent, null);
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(chooser);
            Log.i(TAG, "shareZip: started chooser for " + zipPath);
            return true;
        }
        catch(Exception e)
        {
            Log.e(TAG, "shareZip failed", e);
            return false;
        }
    }
}
