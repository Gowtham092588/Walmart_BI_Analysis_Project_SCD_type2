import boto3
import os

# connecting to AWS s3
s3_resource = boto3.resource('s3', 'us-east-2')

# Function to upload files to AWS s3


def s3_fileupload(file_name, folder, bkt):
    s3_bucket = s3_resource.Bucket(name=bkt)

    try:
        s3_bucket.upload_file(
            Filename=file_name,
            Key=f"{folder}/{os.path.basename(file_name)}"
        )
        return True
    except Exception as e:
        print(f"Upload failed for {file_name}: {e}")
        return False


def s3_multi_upload(file_names, folder, bkt):
    results = {}
    for file_name in file_names:
        success = s3_fileupload(file_name, folder, bkt)
        results[file_name] = success
    return results


if __name__ == "__main__":

    files = [
        'C:\\Users\\yamun\\Desktop\\Walmart_BI Analysis_Mini_Project\\CSV files\\department.csv',
        'C:\\Users\\yamun\\Desktop\\Walmart_BI Analysis_Mini_Project\\CSV files\\fact.csv',
        'C:\\Users\\yamun\\Desktop\\Walmart_BI Analysis_Mini_Project\\CSV files\\stores.csv'
    ]

    status = s3_multi_upload(files, "raw_data", "walmart-s3-raw-data-bucket")

    if (status):
        print('Data is Saved')

    else:

        print('Error while loading data to S3.....')
