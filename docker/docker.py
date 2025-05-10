import argparse
import subprocess
import datetime
import os
import re
import boto3
from logging import exception


######## API ################################################
def get_current_timestamp():
    """Generate a timestamp in the format YYYYMMDDHHMMSS"""
    return datetime.datetime.now().strftime("%Y%m%d%H%M%S")


def create_volume(volume_name):
    print(f"Creating volume '{volume_name}'")
    subprocess.run(["docker", "volume", "create", volume_name], check=True)


def docker_container_exists(container_name):
    """
    Checks if a Docker container with the given name exists using subprocess.

    Args:
        container_name (str): The name of the Docker container to check.

    Returns:
        bool: True if the container exists, False otherwise.
    """
    try:
        # Run the Docker command and capture its output
        result = subprocess.run(
            ["docker", "container", "ps", "-a", "--format", "{{.Names}}"],
            capture_output=True,
            text=True,
            check=True,  # Raise an exception if the command fails
        )

        # Get the output as a string and split it into lines
        container_names = result.stdout.strip().splitlines()

        # Check if the desired container name is in the list
        for name in container_names:
            if name == container_name:
                return True

        return False

    except subprocess.CalledProcessError as e:
        # Handle Docker command errors (e.g., Docker not installed)
        print(f"Error running Docker command: {e}")
        return False
    except FileNotFoundError:
        print("Docker command not found. Please ensure Docker is installed and in your PATH.")
        return False


def create_backup(backup_file, container_name):
    print(f"Creating backup of container '{container_name}' to {backup_file}.")
    try:
        subprocess.run(["docker", "export", "-o", backup_file, container_name], check=True)
        print(f"Backup created successfully: {backup_file}")
        return True
    except Exception as e:
        print(f"Error creating backup for container '{container_name}': {e}")
        return False


def restore_from_backup(backup_file, image_tag):
    print(f"Restoring from {backup_file}.")
    try:
        subprocess.run(["docker", "import", backup_file, image_tag], check=True, stdout=subprocess.DEVNULL)
        print(f"Restore completed successfully as {image_tag}")
        return True
    except Exception as e:
        print(f"Error restoring from backup: {e}")
        return False


def delete_container(container_name):
    print(f"Deleting existing container '{container_name}'")
    try:
        subprocess.run(["docker", "container", "rm", container_name], check=True, stdout=subprocess.DEVNULL)
        print(f"Container deleted successfully")
        return True
    except Exception as e:
        print(f"Error deleting container: {e}")
        return False


def run(image_name, container_name):
    print(f"Running container '{container_name}'")
    try:
        subprocess.run(["docker", "run", "--name", container_name, "-it", image_name], check=True)
        return True
    except Exception as e:
        print(f"Error running container: {e}")
        return False


def run_detached(image_name, container_name):
    print(f"Running container '{container_name}' in detached mode")
    try:
        result = subprocess.run(
            ["docker", "run", "--name", container_name, "-d", image_name],
            capture_output=True,
            text=True,
            check=True
        )
        container_id = result.stdout.strip()
        print(f"Container started with ID: {container_id}")
        print(f"You can attach to it with: docker exec -it {container_name} /bin/bash")
        return True
    except Exception as e:
        print(f"Error running container in detached mode: {e}")
        return False


def run_rm(image_name, container_name):
    print(f"Running container '{container_name}' with auto-removal")
    try:
        subprocess.run(["docker", "run", "--rm", "--name", container_name, "-it", image_name], check=True)
        return True
    except Exception as e:
        print(f"Error running container with auto-removal: {e}")
        return False


def upload_to_s3(backup_file, s3_bucket):
    print(f"Uploading {backup_file} to S3 bucket {s3_bucket}")
    try:
        subprocess.run(["aws", "s3", "cp", backup_file, f"s3://{s3_bucket}/{backup_file}"], check=True)
        print(f"Upload completed successfully")
        return True
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        return False


def download_from_s3(backup_file, s3_bucket):
    print(f"Downloading {backup_file} from S3 bucket {s3_bucket}")
    try:
        subprocess.run(["aws", "s3", "cp", f"s3://{s3_bucket}/{backup_file}", backup_file], check=True)
        print(f"Download completed successfully")
        return True
    except Exception as e:
        print(f"Error downloading from S3: {e}")
        return False


def generate_backup_filename(container_name, use_timestamp=True, timestamp=None):
    """
    Generate a backup filename with a consistent, parseable format
    
    Args:
        container_name (str): Container name
        use_timestamp (bool): Whether to include timestamp
        timestamp (str, optional): Custom timestamp (defaults to current time)
        
    Returns:
        str: Backup filename in format container_name.TIMESTAMP.backup.tar.gz
    """
    if use_timestamp:
        ts = timestamp or get_current_timestamp()
        return f"{container_name}.{ts}.backup.tar.gz"
    else:
        return f"{container_name}.backup.tar.gz"


def parse_backup_filename(backup_file):
    """
    Parse a backup filename to extract container name and timestamp
    
    Args:
        backup_file (str): Backup filename
        
    Returns:
        tuple: (container_name, timestamp) or (container_name, None) if no timestamp
    """
    # Match pattern: name.timestamp.backup.tar.gz
    pattern = r'^(.+)\.(\d{14})\.backup\.tar\.gz$'
    match = re.match(pattern, backup_file)
    
    if match:
        return match.group(1), match.group(2)
    
    # Also handle files without timestamp
    pattern = r'^(.+)\.backup\.tar\.gz$'
    match = re.match(pattern, backup_file)
    
    if match:
        return match.group(1), None
        
    # Fall back to returning the filename without extension if pattern doesn't match
    base_name = os.path.splitext(os.path.splitext(backup_file)[0])[0]
    return base_name, None


def list_s3_backups(s3_bucket, container_prefix=None):
    """
    List available backups in the S3 bucket with optional container prefix filtering
    
    Args:
        s3_bucket (str): S3 bucket name
        container_prefix (str, optional): Filter backups by container prefix
        
    Returns:
        list: List of backup filenames sorted by timestamp (most recent first)
    """
    try:
        # Use boto3 for more complex operations like filtering and sorting
        s3_client = boto3.client('s3')
        response = s3_client.list_objects_v2(Bucket=s3_bucket)
        
        if 'Contents' not in response:
            print(f"No backups found in S3 bucket {s3_bucket}")
            return []
            
        # Get all backup files
        backups = [obj['Key'] for obj in response['Contents'] if obj['Key'].endswith('.backup.tar.gz')]
        
        # Filter by container prefix if specified
        if container_prefix:
            # Match files that start with the prefix followed by a period
            backups = [b for b in backups if b.startswith(f"{container_prefix}.")]
            
        # Sort by timestamp (assuming format container.TIMESTAMP.backup.tar.gz)
        # Extract timestamp using regex and sort
        def get_timestamp(filename):
            _, timestamp = parse_backup_filename(filename)
            return timestamp or "0"  # Default to 0 for files without timestamp
            
        backups.sort(key=get_timestamp, reverse=True)
        return backups
    except Exception as e:
        print(f"Error listing S3 backups: {e}")
        return []


def get_latest_backup(s3_bucket, container_prefix=None):
    """Get the latest backup file from S3"""
    backups = list_s3_backups(s3_bucket, container_prefix)
    if backups:
        return backups[0]  # First item is the most recent
    return None


def get_backups_by_date(s3_bucket, container_prefix=None, date_str=None):
    """
    Get backups from a specific date
    
    Args:
        s3_bucket (str): S3 bucket name
        container_prefix (str, optional): Filter by container prefix
        date_str (str): Date string in format YYYYMMDD
        
    Returns:
        list: List of backup filenames from the specified date
    """
    backups = list_s3_backups(s3_bucket, container_prefix)
    
    if date_str:
        filtered_backups = []
        for backup in backups:
            _, timestamp = parse_backup_filename(backup)
            if timestamp and timestamp.startswith(date_str):
                filtered_backups.append(backup)
        return filtered_backups
    
    return backups


#############  call fncs ###############################
def default(args):
    """Default behavior: check existing container, backup if exists, create new if not"""
    image_name = args.get('image_name', "kalilinux/kali-rolling")
    container_name = args.get('container_name', "kali-vbox")
    use_timestamp = args.get('use_timestamp', False)
    
    # Generate backup filename with new convention
    backup_file = args.get('backup_file') or generate_backup_filename(
        container_name, 
        use_timestamp=use_timestamp
    )
    
    if docker_container_exists(container_name):
        print(f"Container {container_name} exists. Creating backup.")
        create_backup(backup_file, container_name)
        delete_container(container_name)
    
    run(image_name, container_name)


def write_to_tarball_only(args):
    """Save container to local tarball only"""
    container_name = args.get('container_name')
    use_timestamp = args.get('use_timestamp', True)
    
    # Generate backup filename with new convention
    backup_file = args.get('backup_file') or generate_backup_filename(
        container_name, 
        use_timestamp=use_timestamp
    )
    
    print(f"Writing to tarball: {backup_file}")
    create_backup(backup_file, container_name)


def write_to_aws_only(args):
    """Save container to AWS S3 only"""
    container_name = args.get('container_name')
    s3_bucket = args.get('s3_bucket')
    use_timestamp = args.get('use_timestamp', True)
    
    # Generate backup filename with new convention
    backup_file = generate_backup_filename(
        container_name, 
        use_timestamp=use_timestamp
    )
    
    print(f"Writing to AWS S3: {backup_file}")
    if create_backup(backup_file, container_name):
        upload_to_s3(backup_file, s3_bucket)
        # Clean up local file after upload if specified
        if args.get('cleanup_local', True):
            os.remove(backup_file)
            print(f"Removed local backup file {backup_file}")


def write_to_tarball_and_aws(args):
    """Save container to both local tarball and AWS S3"""
    container_name = args.get('container_name')
    s3_bucket = args.get('s3_bucket')
    use_timestamp = args.get('use_timestamp', True)
    
    # Generate backup filename with new convention
    backup_file = generate_backup_filename(
        container_name, 
        use_timestamp=use_timestamp
    )
    
    print(f"Writing to tarball and AWS S3: {backup_file}")
    if create_backup(backup_file, container_name):
        upload_to_s3(backup_file, s3_bucket)


def write_to_tarball_and_aws_and_run_local(args):
    """Save container to tarball and AWS, then run it locally"""
    container_name = args.get('container_name')
    image_name = args.get('image_name')
    s3_bucket = args.get('s3_bucket')
    use_timestamp = args.get('use_timestamp', True)
    
    # Generate backup filename with new convention
    timestamp = get_current_timestamp()
    backup_file = generate_backup_filename(
        container_name, 
        use_timestamp=use_timestamp,
        timestamp=timestamp
    )
    
    # Generate a new container name with timestamp if requested
    new_container_name = container_name
    if use_timestamp:
        new_container_name = f"{container_name}_{timestamp}"
    
    print(f"Writing to tarball and AWS & running locally")
    if create_backup(backup_file, container_name):
        upload_to_s3(backup_file, s3_bucket)
        image_tag = f"{image_name}:backup"
        if restore_from_backup(backup_file, image_tag):
            run_detached(image_tag, new_container_name)


def download_latest_from_aws(args):
    """Download latest backup from AWS S3"""
    container_name = args.get('container_name')
    s3_bucket = args.get('s3_bucket')
    
    latest_backup = get_latest_backup(s3_bucket, container_name)
    if latest_backup:
        print(f"Found latest backup: {latest_backup}")
        download_from_s3(latest_backup, s3_bucket)
    else:
        print(f"No backups found for container {container_name} in bucket {s3_bucket}")


def download_latest_from_aws_and_restore(args):
    """Download latest backup from AWS S3 and restore it"""
    container_name = args.get('container_name')
    image_name = args.get('image_name')
    s3_bucket = args.get('s3_bucket')
    
    latest_backup = get_latest_backup(s3_bucket, container_name)
    if latest_backup:
        print(f"Found latest backup: {latest_backup}")
        if download_from_s3(latest_backup, s3_bucket):
            image_tag = f"{image_name}:backup"
            restore_from_backup(latest_backup, image_tag)
            print(f"Successfully restored image: {image_tag}")
    else:
        print(f"No backups found for container {container_name} in bucket {s3_bucket}")


def download_latest_from_aws_and_run(args):
    """Download latest backup from AWS S3, restore it, and run container"""
    container_name = args.get('container_name')
    image_name = args.get('image_name')
    s3_bucket = args.get('s3_bucket')
    use_timestamp = args.get('use_timestamp', True)
    
    # Generate a new container name with timestamp if requested
    new_container_name = container_name
    if use_timestamp:
        timestamp = get_current_timestamp()
        new_container_name = f"{container_name}_{timestamp}"
    
    latest_backup = get_latest_backup(s3_bucket, container_name)
    if latest_backup:
        print(f"Found latest backup: {latest_backup}")
        if download_from_s3(latest_backup, s3_bucket):
            image_tag = f"{image_name}:backup"
            if restore_from_backup(latest_backup, image_tag):
                run_detached(image_tag, new_container_name)
    else:
        print(f"No backups found for container {container_name} in bucket {s3_bucket}")
        print(f"Pulling latest image from Docker Hub instead")
        run_detached(image_name, new_container_name)


def download_by_date(args):
    """Download backups from a specific date"""
    container_name = args.get('container_name')
    s3_bucket = args.get('s3_bucket')
    date_str = args.get('date')
    
    if not date_str:
        print("Please provide a date in format YYYYMMDD")
        return
    
    backups = get_backups_by_date(s3_bucket, container_name, date_str)
    if backups:
        print(f"Found {len(backups)} backups from {date_str}:")
        for i, backup in enumerate(backups):
            print(f"{i+1}. {backup}")
        
        if args.get('download_all', False):
            print("Downloading all backups...")
            for backup in backups:
                download_from_s3(backup, s3_bucket)
        else:
            print("Use --download_backup <filename> to download a specific backup")
    else:
        print(f"No backups found for container {container_name} from date {date_str}")


def list_available_backups(args):
    """List all available backups in S3 bucket"""
    s3_bucket = args.get('s3_bucket')
    container_prefix = args.get('container_name', None)
    
    backups = list_s3_backups(s3_bucket, container_prefix)
    if backups:
        print(f"Available backups in S3 bucket {s3_bucket}:")
        for i, backup in enumerate(backups):
            container, timestamp = parse_backup_filename(backup)
            date_str = f"{timestamp[:4]}-{timestamp[4:6]}-{timestamp[6:8]} {timestamp[8:10]}:{timestamp[10:12]}:{timestamp[12:14]}" if timestamp else "No timestamp"
            print(f"{i+1}. {backup} (Container: {container}, Date: {date_str})")
    else:
        print(f"No backups found in S3 bucket {s3_bucket}")


def execute(args):
    """Route to the appropriate function based on provided arguments"""
    # Convert args Namespace to dictionary for easier handling
    args_dict = vars(args) if isinstance(args, argparse.Namespace) else args
    
    # Define command routing
    if args_dict.get('list_backups'):
        return list_available_backups(args_dict)
    
    if args_dict.get('date'):
        return download_by_date(args_dict)
        
    if args_dict.get('download_backup'):
        specific_backup = args_dict.get('download_backup')
        return download_from_s3(specific_backup, args_dict.get('s3_bucket'))
        
    if args_dict.get('save'):
        if args_dict.get('tar') and args_dict.get('aws'):
            return write_to_tarball_and_aws(args_dict)
        elif args_dict.get('tar'):
            return write_to_tarball_only(args_dict)
        elif args_dict.get('aws'):
            return write_to_aws_only(args_dict)
        else:
            print("Please provide --aws or --tar flags with --save")
            return
    
    if args_dict.get('pull'):
        if args_dict.get('restore') and args_dict.get('run'):
            return download_latest_from_aws_and_run(args_dict)
        elif args_dict.get('restore'):
            return download_latest_from_aws_and_restore(args_dict)
        else:
            return download_latest_from_aws(args_dict)
    
    if args_dict.get('run'):
        if docker_container_exists(args_dict.get('container_name')):
            print(f"Container {args_dict.get('container_name')} already exists. Use --save first.")
            return
        else:
            return run_detached(args_dict.get('image_name'), args_dict.get('container_name'))
    
    # Default behavior if no specific command matches
    return default(args_dict)


######################## helper fcns ############################
def ibool(v):
    if isinstance(v, bool):
        return v
    if v is None:
        return False
    if isinstance(v, str):
        return v.lower() in ('true', 't', '1', 'yes', 'y')
    return bool(int(v))


############## MAIN ###########################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Docker Container Backup and Restore Tool")
    
    # Basic container and image options
    parser.add_argument("--image_name", type=str, default="kalilinux/kali-rolling", 
                        help="Docker image name (default: kalilinux/kali-rolling)")
    parser.add_argument("--container_name", type=str, default="kali-vbox", 
                        help="Docker container name or prefix (default: kali-vbox)")
    parser.add_argument("--backup_file", type=str, 
                        help="Backup file name (default: auto-generated)")
    parser.add_argument("--s3_bucket", type=str, default="montaniz-bucket", 
                        help="S3 bucket name (default: montaniz-bucket)")
    
    # Command flags
    parser.add_argument("--save", action="store_true", 
                        help="Save container backup")
    parser.add_argument("--pull", action="store_true", 
                        help="Pull latest backup from S3")
    parser.add_argument("--restore", action="store_true", 
                        help="Restore container from backup")
    parser.add_argument("--run", action="store_true", 
                        help="Run container after operation")
    parser.add_argument("--list_backups", action="store_true", 
                        help="List available backups in S3")
    
    # Storage options
    parser.add_argument("--tar", action="store_true", 
                        help="Save backup to local tarball")
    parser.add_argument("--aws", action="store_true", 
                        help="Save backup to AWS S3")
    
    # Date-based filtering
    parser.add_argument("--date", type=str, 
                        help="Filter backups by date (format: YYYYMMDD)")
    parser.add_argument("--download_backup", type=str, 
                        help="Download a specific backup file")
    parser.add_argument("--download_all", action="store_true", 
                        help="Download all backups matching criteria")
    
    # Additional options
    parser.add_argument("--use_timestamp", action="store_true", 
                        help="Use timestamp in container and backup names")
    parser.add_argument("--cleanup_local", action="store_true", 
                        help="Remove local backup file after S3 upload")
    
    args = parser.parse_args()
    
    # Execute the appropriate function based on arguments
    execute(args)