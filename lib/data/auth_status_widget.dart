import 'package:flutter/material.dart';
import 'auth_persistence_service.dart';
import 'globals.dart';

/// Widget to display authentication status and provide login/logout controls
class AuthStatusWidget extends StatefulWidget {
  const AuthStatusWidget({super.key});

  @override
  State<AuthStatusWidget> createState() => _AuthStatusWidgetState();
}

class _AuthStatusWidgetState extends State<AuthStatusWidget> {
  Map<String, dynamic> _authStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateAuthStatus();
  }

  void _updateAuthStatus() {
    setState(() {
      _authStatus = AuthPersistenceService.instance.getStatus();
    });
  }

  Future<void> _refreshAuthStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthPersistenceService.instance.forceAuthCheck();
      _updateAuthStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing auth status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthPersistenceService.instance.syncAllData();
      _updateAuthStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authStatus['isAuthenticated'] ?? false;
    final currentUserId = _authStatus['currentUserId'];
    final lastAuthCheck = _authStatus['lastAuthCheck'];
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.verified_user : Icons.person_off,
                  color: isAuthenticated ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Authentication Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isAuthenticated ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : _refreshAuthStatus,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh authentication status',
                ),
              ],
            ),
            const Divider(),
            
            // Authentication Status
            _buildStatusRow(
              'Status:',
              isAuthenticated ? 'Logged In' : 'Not Logged In',
              color: isAuthenticated ? Colors.green : Colors.red,
            ),
            
            if (isAuthenticated) ...[
              _buildStatusRow(
                'User ID:',
                currentUserId ?? 'Unknown',
                isLongText: true,
              ),
              _buildStatusRow(
                'Email:',
                UserDetails.email.isNotEmpty ? UserDetails.email : 'Not available',
                isLongText: true,
              ),
              _buildStatusRow(
                'Name:',
                '${UserDetails.firstName} ${UserDetails.lastName}'.trim(),
              ),
            ],
            
            if (lastAuthCheck != null) ...[
              _buildStatusRow(
                'Last Check:',
                _formatTimestamp(lastAuthCheck),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            if (isAuthenticated) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _syncData,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sync Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Go to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAuthenticated ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAuthenticated ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Information:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isAuthenticated ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAuthenticated 
                        ? '• You are logged in and your data is being synced\n'
                          '• Data is automatically saved locally and to the cloud\n'
                          '• You will stay logged in even after closing the app\n'
                          '• All your progress and settings are preserved'
                        : '• Please log in to sync your data across devices\n'
                          '• Your data is saved locally but not backed up to the cloud\n'
                          '• Log in to access your data from other devices',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? color, bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontSize: isLongText ? 11 : 14,
              ),
              maxLines: isLongText ? 2 : 1,
              overflow: isLongText ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
