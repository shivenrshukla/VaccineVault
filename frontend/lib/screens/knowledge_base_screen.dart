import 'package:flutter/material.dart';
import '../widgets/disclaimer_dialog.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';

  final List<String> categories = [
    'All',
    'COVID-19',
    'Routine Immunization',
    'Travel Vaccines',
    'Special Purpose',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDisclaimerDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredVaccines = _getFilteredVaccines();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5FBF),
              Color(0xFFB794F6),
              Color(0xFFD6BCFA),
              Color(0xFFFFB3BA),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Knowledge Base',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search vaccines or diseases...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B5FBF),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Filter
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF8B5FBF)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Vaccine Cards List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredVaccines.length,
                    itemBuilder: (context, index) {
                      return _buildVaccineCard(filteredVaccines[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredVaccines() {
    List<Map<String, dynamic>> vaccines = _getAllVaccines();

    // Filter by category
    if (selectedCategory != 'All') {
      vaccines = vaccines
          .where((v) => v['category'] == selectedCategory)
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      vaccines = vaccines.where((v) {
        return v['name'].toLowerCase().contains(searchQuery) ||
            v['disease'].toLowerCase().contains(searchQuery);
      }).toList();
    }

    return vaccines;
  }

  Widget _buildVaccineCard(Map<String, dynamic> vaccine) {
    return GestureDetector(
      onTap: () {
        _showVaccineDetails(vaccine);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(vaccine['color']),
                    Color(vaccine['color']).withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(vaccine['icon'], color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccine['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protects against: ${vaccine['disease']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),

            // Quick Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.medical_services,
                    'Efficacy',
                    vaccine['efficacy'],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Doses',
                    vaccine['doses'],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    'Protection',
                    vaccine['protection'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B5FBF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }

  void _showVaccineDetails(Map<String, dynamic> vaccine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Vaccine Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(vaccine['color']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vaccine['icon'],
                      color: Color(vaccine['color']),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccine['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          vaccine['disease'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mechanism
              _buildDetailSection(
                'Mechanism of Action',
                vaccine['mechanism'],
                Icons.science,
              ),
              const SizedBox(height: 16),

              // Efficacy
              _buildDetailSection(
                'Efficacy',
                vaccine['efficacy'],
                Icons.trending_up,
              ),
              const SizedBox(height: 16),

              // Dosage
              _buildDetailSection(
                'Dosage & Administration',
                '${vaccine['doses']}\n${vaccine['administration']}',
                Icons.medication,
              ),
              const SizedBox(height: 16),

              // Protection Duration
              _buildDetailSection(
                'Protection Duration',
                vaccine['protection'],
                Icons.shield,
              ),
              const SizedBox(height: 16),

              // Cost
              _buildDetailSection(
                'Cost',
                vaccine['cost'],
                Icons.currency_rupee,
              ),
              const SizedBox(height: 16),

              // Side Effects
              _buildDetailSection(
                'Side Effects',
                vaccine['sideEffects'],
                Icons.warning_amber,
              ),
              const SizedBox(height: 24),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllVaccines() {
    return [
      // COVID-19 Vaccines
      {
        'name': 'Covishield',
        'disease': 'COVID-19',
        'category': 'COVID-19',
        'icon': Icons.coronavirus,
        'color': 0xFF6B46C1,
        'efficacy':
            '70-90% against symptomatic infection, higher against severe disease',
        'doses': '2 doses, 4-12 weeks apart',
        'administration': 'Intramuscular injection',
        'protection': '6 months (booster recommended)',
        'cost': '₹300-600 per dose',
        'mechanism':
            'Adenovirus-vectored vaccine using weakened chimpanzee adenovirus to deliver SARS-CoV-2 spike protein code',
        'sideEffects':
            'Common: Injection site pain, fatigue, headache, fever\nRare: Blood clotting issues',
      },
      {
        'name': 'Covaxin',
        'disease': 'COVID-19',
        'category': 'COVID-19',
        'icon': Icons.coronavirus,
        'color': 0xFF553C9A,
        'efficacy':
            '78% against symptomatic COVID-19, 93% against severe disease',
        'doses': '2 doses, 4 weeks apart',
        'administration': 'Intramuscular injection',
        'protection': '6-12 months (booster recommended)',
        'cost': '₹600-1,200 per dose',
        'mechanism':
            'Inactivated whole-virus vaccine that stimulates immune system to produce antibodies',
        'sideEffects':
            'Common: Pain at injection site, fever, fatigue, body ache\nRare: Anaphylaxis, blood clotting disorders',
      },
      {
        'name': 'ZyCoV-D',
        'disease': 'COVID-19',
        'category': 'COVID-19',
        'icon': Icons.coronavirus,
        'color': 0xFF8B5FBF,
        'efficacy': '66.6% against symptomatic COVID-19',
        'doses': '3 doses, 28 days apart',
        'administration': 'Needle-free intramuscular injection',
        'protection': '6 months (booster recommended)',
        'cost': '₹1,200-1,400 per dose',
        'mechanism':
            'DNA plasmid vaccine delivering spike protein genetic code',
        'sideEffects':
            'Common: Injection site pain, fever, headache, fatigue\nRare: Anaphylaxis, allergic reactions',
      },

      // Routine Immunization
      {
        'name': 'BCG Vaccine',
        'disease': 'Tuberculosis (TB)',
        'category': 'Routine Immunization',
        'icon': Icons.baby_changing_station,
        'color': 0xFFB794F6,
        'efficacy': '70-80% reduction in severe childhood TB',
        'doses': 'Single dose at birth',
        'administration': '0.05ml (under 1 month) or 0.1ml (over 1 month)',
        'protection': 'Long-lasting, usually lifetime',
        'cost': 'Free under UIP, ₹80-1,050 in private',
        'mechanism': 'Live attenuated Mycobacterium bovis preparation',
        'sideEffects':
            'Normal: Small tender red swelling, may form vesicle\nRare: Severe local reaction',
      },
      {
        'name': 'DPT Vaccine',
        'disease': 'Diphtheria, Pertussis, Tetanus',
        'category': 'Routine Immunization',
        'icon': Icons.child_care,
        'color': 0xFF9F7AEA,
        'efficacy': 'Highly effective against all three diseases',
        'doses': 'Primary series + boosters at 16-24 months and 5-6 years',
        'administration': 'Intramuscular injection',
        'protection': 'Requires regular boosters',
        'cost': '₹890-1,299 per dose in private',
        'mechanism':
            'Contains toxoids and bacterial components to stimulate immunity',
        'sideEffects':
            'Common: Pain at injection site, mild fever\nRare: Anaphylaxis, encephalopathy (within 7 days)',
      },
      {
        'name': 'Hepatitis B Vaccine',
        'disease': 'Hepatitis B',
        'category': 'Routine Immunization',
        'icon': Icons.local_hospital,
        'color': 0xFF6B46C1,
        'efficacy': 'Highly effective, prevents 72% of liver cancer',
        'doses': '3 doses: at birth, 6 weeks, 6 months',
        'administration': 'Intramuscular injection',
        'protection': 'Long-lasting, possibly lifetime',
        'cost': 'Free under UIP',
        'mechanism':
            'Recombinant vaccine - first vaccine labeled as "anti-cancer"',
        'sideEffects':
            'Mild: Pain at injection site, dizziness, headache\nContraindicated: Yeast allergy',
      },
      {
        'name': 'MMR Vaccine',
        'disease': 'Measles, Mumps, Rubella',
        'category': 'Routine Immunization',
        'icon': Icons.face,
        'color': 0xFF553C9A,
        'efficacy':
            '1 dose: 93% measles, 72% mumps, 97% rubella\n2 doses: 97% measles, 86% mumps, 99% rubella',
        'doses': '3 doses: 9-12 months, 15-18 months, 4-6 years',
        'administration': 'Subcutaneous injection (upper arm or thigh)',
        'protection': 'Long-lasting immunity',
        'cost': '₹150-600 per dose',
        'mechanism': 'Live attenuated virus strains',
        'sideEffects':
            'Mild: Soreness, redness, swelling at site, fever, mild rash',
      },
      {
        'name': 'Rotavirus Vaccine',
        'disease': 'Rotavirus Gastroenteritis',
        'category': 'Routine Immunization',
        'icon': Icons.water_drop,
        'color': 0xFF8B5FBF,
        'efficacy':
            '90% effective against severe rotavirus, ROTAVAC 56% against severe gastroenteritis',
        'doses':
            'Rotarix: 2 doses (6, 10 weeks)\nRotavac/Rotasiil: 3 doses (6, 10, 14 weeks)',
        'administration': 'Oral drops',
        'protection': 'First year of life, all doses before 8 months',
        'cost': 'Free under UIP for ROTAVAC',
        'mechanism': 'Live oral vaccine',
        'sideEffects':
            'Common: Diarrhoea, fever, irritability, abdominal pain\nContraindicated: History of intussusception or SCID',
      },
      {
        'name': 'OPV (Oral Polio Vaccine)',
        'disease': 'Poliomyelitis',
        'category': 'Routine Immunization',
        'icon': Icons.accessibility,
        'color': 0xFFB794F6,
        'efficacy': 'Nearly 100% seroconversion after 3 doses',
        'doses':
            'Primary: 3 doses (6, 10, 14 weeks) + birth dose\nBoosters: 16-18 months, 4-6 years',
        'administration': 'Oral drops',
        'protection': 'Provides intestinal immunity',
        'cost': 'Free under UIP',
        'mechanism': 'Weakened live poliovirus',
        'sideEffects':
            'Common: Headache, abdominal pain, fever, diarrhoea\nRare: Vaccine-derived poliovirus (VDPV)',
      },

      // Travel Vaccines
      {
        'name': 'Yellow Fever Vaccine',
        'disease': 'Yellow Fever',
        'category': 'Travel Vaccines',
        'icon': Icons.flight_takeoff,
        'color': 0xFF9F7AEA,
        'efficacy': 'Highly effective (>95%)',
        'doses': 'Single dose',
        'administration': 'Subcutaneous injection',
        'protection': 'Lifetime (certificate valid for life)',
        'cost': 'Available at authorized govt centers',
        'mechanism': 'Live attenuated virus',
        'sideEffects': 'Mild: Fever, headache, muscle aches',
      },
      {
        'name': 'Typhoid Vaccine (TCV)',
        'disease': 'Typhoid Fever',
        'category': 'Travel Vaccines',
        'icon': Icons.restaurant,
        'color': 0xFF6B46C1,
        'efficacy': '81-85% protection',
        'doses': 'Single dose',
        'administration': 'Intramuscular injection',
        'protection': 'Up to 5 years',
        'cost': '₹500-1,200 per dose',
        'mechanism': 'Conjugate vaccine linking bacterial sugar to protein',
        'sideEffects': 'Mild: Fever, tenderness at injection site',
      },
      {
        'name': 'Hepatitis A Vaccine',
        'disease': 'Hepatitis A',
        'category': 'Travel Vaccines',
        'icon': Icons.local_dining,
        'color': 0xFF553C9A,
        'efficacy': 'Around 95% protection',
        'doses': '2 doses, 6 months apart',
        'administration': 'Intramuscular injection',
        'protection': '20 years or more',
        'cost': '₹800-1,800 per dose',
        'mechanism': 'Inactivated virus',
        'sideEffects': 'Mild: Soreness at injection site, fever, fatigue',
      },
      {
        'name': 'Japanese Encephalitis Vaccine',
        'disease': 'Japanese Encephalitis',
        'category': 'Travel Vaccines',
        'icon': Icons.bug_report,
        'color': 0xFF8B5FBF,
        'efficacy': 'Highly effective (>90%)',
        'doses': '2 doses, 28 days apart',
        'administration': 'Intramuscular injection',
        'protection': '1-2 years (booster may be needed)',
        'cost': 'Free under UIP in endemic areas',
        'mechanism': 'Inactivated virus',
        'sideEffects': 'Mild: Fever, headache, muscle pain',
      },

      // Special Purpose Vaccines
      {
        'name': 'HPV Vaccine',
        'disease': 'Cervical Cancer (Human Papillomavirus)',
        'category': 'Special Purpose',
        'icon': Icons.health_and_safety,
        'color': 0xFFB794F6,
        'efficacy': '98-100% protection against dangerous HPV types',
        'doses':
            'Under 15: 2 doses, 6 months apart\n15+: 3 doses over 6 months',
        'administration': 'Intramuscular injection (deltoid)',
        'protection': '6-10 years, possibly longer',
        'cost': '₹2,000-10,000 per dose',
        'mechanism': 'Virus-like particles (VLPs) that mimic HPV',
        'sideEffects': 'Mild: Pain at injection site, fatigue, headaches',
      },
      {
        'name': 'Rabies Vaccine',
        'disease': 'Rabies',
        'category': 'Special Purpose',
        'icon': Icons.pets,
        'color': 0xFF9F7AEA,
        'efficacy': 'Nearly 100% effective if given properly',
        'doses':
            'Pre-exposure: 3 doses (0, 7, 21-28 days)\nPost-exposure: 4-5 doses',
        'administration': 'Intramuscular or intradermal',
        'protection': 'Pre-exposure: 3-5 years\nPost-exposure: Lifelong',
        'cost': '₹500-1,000 per dose',
        'mechanism': 'Inactivated rabies virus',
        'sideEffects': 'Mild: Pain/redness at site, mild fever, headache',
      },
      {
        'name': 'Influenza (Flu) Vaccine',
        'disease': 'Seasonal Influenza',
        'category': 'Special Purpose',
        'icon': Icons.ac_unit,
        'color': 0xFF6B46C1,
        'efficacy': '40-60% effective (varies by strain match)',
        'doses': 'Annual single dose',
        'administration': 'Intramuscular injection or nasal spray',
        'protection': 'About 1 year',
        'cost': '₹300-700 per dose',
        'mechanism': 'Inactivated or weakened flu viruses',
        'sideEffects': 'Mild: Soreness, fever, muscle aches',
      },
      {
        'name': 'Pneumococcal Vaccine',
        'disease': 'Pneumonia, Meningitis',
        'category': 'Special Purpose',
        'icon': Icons.air,
        'color': 0xFF553C9A,
        'efficacy': 'Highly effective against vaccine strains',
        'doses':
            'PCV: 3-4 doses in infancy\nPPSV23: 1-2 doses for elderly/at-risk',
        'administration': 'Intramuscular injection',
        'protection': 'Years to decades depending on type',
        'cost': 'Free under UIP (PCV13)',
        'mechanism': 'Polysaccharide or conjugate vaccine',
        'sideEffects': 'Mild: Redness, pain at site, mild fever',
      },
    ];
  }
}
