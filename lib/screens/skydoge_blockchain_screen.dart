import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

/// Tela educacional/demonstrativa sobre Skydoge Blockchain
class SkyDogeBlockchainScreen extends StatefulWidget {
  const SkyDogeBlockchainScreen({Key? key}) : super(key: key);

  @override
  State<SkyDogeBlockchainScreen> createState() => _SkyDogeBlockchainScreenState();
}

class _SkyDogeBlockchainScreenState extends State<SkyDogeBlockchainScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  Timer? _blockTimer;
  
  List<BlockInfo> _recentBlocks = [];
  int _currentBlockHeight = 245789;
  double _networkHashrate = 1234.56;
  int _activeNodes = 127;
  String _lastBlockTime = '2 min atrás';
  
  final Map<String, dynamic> _networkStats = {
    'difficulty': '45.2M',
    'blockReward': '50 SKYDOGE',
    'avgBlockTime': '10 min',
    'totalSupply': '21M SKYDOGE',
  };

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _generateInitialBlocks();
    _startBlockMining();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _blockTimer?.cancel();
    super.dispose();
  }

  void _generateInitialBlocks() {
    final random = Random();
    for (int i = 0; i < 5; i++) {
      _recentBlocks.add(BlockInfo(
        height: _currentBlockHeight - i,
        hash: _generateHash(),
        timestamp: DateTime.now().subtract(Duration(minutes: i * 10)),
        transactions: random.nextInt(50) + 10,
        miner: 'Miner${random.nextInt(999)}',
        reward: 50.0,
      ));
    }
  }

  void _startBlockMining() {
    _blockTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentBlockHeight++;
          _recentBlocks.insert(0, BlockInfo(
            height: _currentBlockHeight,
            hash: _generateHash(),
            timestamp: DateTime.now(),
            transactions: Random().nextInt(50) + 10,
            miner: 'Miner${Random().nextInt(999)}',
            reward: 50.0,
          ));
          
          if (_recentBlocks.length > 10) {
            _recentBlocks.removeLast();
          }
          
          _lastBlockTime = '0 seg atrás';
          _networkHashrate = 1200 + Random().nextDouble() * 100;
        });
      }
    });
  }

  String _generateHash() {
    final random = Random();
    return List.generate(64, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple, Colors.pink],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_tree, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              'SKYDOGE BLOCKCHAIN',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _generateInitialBlocks();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildNetworkStatusCard(),
              const SizedBox(height: 16),
              _buildRecentBlocksSection(),
              const SizedBox(height: 16),
              _buildDrivechainSection(),
              const SizedBox(height: 16),
              _buildSidechainsSection(),
              const SizedBox(height: 16),
              _buildLinksSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.purple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(_pulseController.value),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'REDE ONLINE',
                style: GoogleFonts.orbitron(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildStatTile('Altura do Bloco', '$_currentBlockHeight', Icons.layers),
              _buildStatTile('Hashrate', '${_networkHashrate.toStringAsFixed(2)} TH/s', Icons.speed),
              _buildStatTile('Nós Ativos', '$_activeNodes', Icons.hub),
              _buildStatTile('Último Bloco', _lastBlockTime, Icons.access_time),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Dificuldade', _networkStats['difficulty']),
              _buildMiniStat('Recompensa', _networkStats['blockReward']),
              _buildMiniStat('Tempo Médio', _networkStats['avgBlockTime']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBlocksSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '📦 BLOCOS RECENTES',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._recentBlocks.map((block) => _buildBlockCard(block)).toList(),
        ],
      ),
    );
  }

  Widget _buildBlockCard(BlockInfo block) {
    final age = DateTime.now().difference(block.timestamp);
    final ageString = age.inMinutes < 1 
        ? '${age.inSeconds} seg atrás' 
        : '${age.inMinutes} min atrás';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${block.height}',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ageString,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '${block.transactions} txs',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.tag, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: block.hash));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hash copiado!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    '${block.hash.substring(0, 16)}...${block.hash.substring(block.hash.length - 8)}',
                    style: GoogleFonts.courierPrime(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.copy, color: Colors.white54, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    block.miner,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '⚡ ${block.reward} SKYDOGE',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivechainSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.red.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'TECNOLOGIA DRIVECHAIN',
                style: GoogleFonts.orbitron(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Skydoge implementa Drivechain (BIPs 300 e 301), permitindo:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('🔗', 'Sidechains totalmente funcionais'),
          _buildFeatureItem('🔄', 'Transferência bidirecional de moedas'),
          _buildFeatureItem('🛡️', 'Segurança da mainchain preservada'),
          _buildFeatureItem('🚀', 'Experimentação sem riscos'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidechainsSection() {
    final sidechains = [
      {
        'name': 'EthSide',
        'description': 'Compatibilidade EVM completa',
        'icon': '⚡',
        'color': Colors.purple
      },
      {
        'name': 'Thunder',
        'description': 'Escalabilidade e velocidade',
        'icon': '⚡',
        'color': Colors.blue
      },
      {
        'name': 'BitAssets',
        'description': 'NFTs e ativos digitais',
        'icon': '🎨',
        'color': Colors.pink
      },
      {
        'name': 'BitDNS',
        'description': 'Domínios descentralizados',
        'icon': '🌐',
        'color': Colors.green
      },
      {
        'name': 'Hivemind',
        'description': 'Oráculo descentralizado',
        'icon': '🔮',
        'color': Colors.orange
      },
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '🌌 SIDECHAINS DISPONÍVEIS',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...sidechains.map((sidechain) => _buildSidechainCard(
            sidechain['name'] as String,
            sidechain['description'] as String,
            sidechain['icon'] as String,
            sidechain['color'] as Color,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSidechainCard(String name, String description, String icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }

  Widget _buildLinksSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔗 LINKS ÚTEIS',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLinkItem('Website Oficial', 'https://skydoge.net'),
          _buildLinkItem('Whitepaper', 'https://skydoge.net/whitepaper.pdf'),
          _buildLinkItem('GitHub', 'https://github.com/skydogenet'),
          _buildLinkItem('Block Explorer', 'http://explorer.skydoge.net'),
          _buildLinkItem('Drivechain Info', 'https://www.drivechain.info/'),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                Text(
                  url.split('/')[2],
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    decoration: TextDecoration.underline, // Visual de link
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new, color: Colors.cyanAccent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            Text('Sobre Skydoge',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                  'Esta é uma tela educacional/demonstrativa sobre a blockchain Skydoge.',
                  style: TextStyle(color: Colors.white70, height: 1.5)),
              SizedBox(height: 16),
              Text('📚 O que você está vendo:', style: TextStyle(
                  color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '• Blocos sendo "minerados" em tempo real (simulação)\n• Estatísticas da rede (dados ilustrativos)\n• Informações sobre tecnologia Drivechain\n• Sidechains disponíveis na rede',
                  style: TextStyle(color: Colors.white70, height: 1.5)),
              SizedBox(height: 16),
              Text('⚠️ Importante:', style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'Esta é uma demonstração educacional. Para conectar à blockchain real, seria necessário implementar:\n\n• Cliente RPC ou SDK\n• Sistema de carteiras\n• Gerenciamento de chaves\n• Assinatura de transações',
                  style: TextStyle(color: Colors.white70, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }
}

class BlockInfo {
  final int height;
  final String hash;
  final DateTime timestamp;
  final int transactions;
  final String miner;
  final double reward;

  BlockInfo({
    required this.height,
    required this.hash,
    required this.timestamp,
    required this.transactions,
    required this.miner,
    required this.reward,
  });
}
