

import 'package:cliqueledger/api_helpers/clique_media.dart';
import 'package:cliqueledger/api_helpers/fetch_transactions.dart';
import 'package:cliqueledger/api_helpers/report_api.dart';
import 'package:cliqueledger/api_helpers/transaction_post.dart';
import 'package:cliqueledger/models/Participants_post.dart';
import 'package:cliqueledger/models/Transaction_post_schema.dart';
import 'package:cliqueledger/models/abstruct_report.dart';

import 'package:cliqueledger/providers/Clique_list_provider.dart';
import 'package:cliqueledger/providers/transaction_provider.dart';
import 'package:cliqueledger/providers/clique_provider.dart';
import 'package:cliqueledger/providers/reports_provider.dart';
import 'package:cliqueledger/providers/clique_media_provider.dart';
import 'package:cliqueledger/service/authservice.dart';

import 'package:cliqueledger/utility/routers_constant.dart';
import 'package:cliqueledger/widgets/media_tab.dart';

import 'package:flutter/material.dart';
import 'package:cliqueledger/models/transaction.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';


class Cliquepage extends StatefulWidget {
  const Cliquepage({super.key});

  @override
  State<Cliquepage> createState() => _CliquepageState();
}

class _CliquepageState extends State<Cliquepage>
    with SingleTickerProviderStateMixin {
  final TransactionList transactionList = TransactionList();
  final ReportApi reportApi = ReportApi();

  late TransactionProvider transactionProvider;
  late CliqueProvider cliqueProvider;
  late TabController _tabController;
  bool isGenerateButtonClicked = false;

  PickImage pickImage = PickImage();

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cliqueProvider = context.read<CliqueProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final cliqueMediaProvider = context.read<CliqueMediaProvider>();
      fetchTransactions(cliqueProvider, transactionProvider);
      if (cliqueProvider.currentClique != null) {
        CliqueMedia.getMedia(
            cliqueMediaProvider, cliqueProvider.currentClique!.id);
      }
    });
  }

  Future<void> fetchTransactions(CliqueProvider cliqueProvider,
      TransactionProvider transactionProvider) async {
    if (cliqueProvider.currentClique != null) {
      final cliqueId = cliqueProvider.currentClique!.id;
      if (!transactionProvider.transactionMap.containsKey(cliqueId)) {
        print('Clique Id : $cliqueId');
        await transactionList.fetchData(cliqueId);
        transactionProvider.addAllTransaction(
            cliqueId, transactionList.transactions);
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getAbstructReport(String cliqueId,
      ReportsProvider reportsProvider, BuildContext context) async {
    setState(() {
      isLoading = true; // Show loading while fetching
    });
    try {
      await reportApi.getOverAllReport(cliqueId, reportsProvider, context);
    } catch (e) {
      print("Error fetching abstract report: $e");
    } finally {
      setState(() {
        isLoading = false; // Hide loading after fetching
      });
    }
  }

  void _createTransaction(
      BuildContext context,
      CliqueProvider cliqueProvider,
      TransactionProvider transactionProvider,
      CliqueListProvider cliqueListProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Define state variables
        String transactionType = 'spend';
        num amount = 0.0;
        List<Map<String, String>> selectedMembers = [];
        String? amountError;
        String? transactionTypeError;
        String description = "Description is not Present";
        String? descriptionError;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final theme = Theme.of(context); // Get current theme

            // Calculate available height by considering the keyboard height
            double availableHeight = MediaQuery.of(context).size.height -
                MediaQuery.of(context).viewInsets.bottom -
                100;

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Text(
                'Create Transaction',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.titleSmall?.color,
                ),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: double.maxFinite,
                  constraints: BoxConstraints(maxHeight: availableHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Amount Field
                      TextFormField(
                        cursorColor: theme.colorScheme.tertiary,
                        decoration: InputDecoration(
                          floatingLabelStyle:
                              TextStyle(color: theme.colorScheme.tertiary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          labelText: 'Amount',
                          border: const OutlineInputBorder(),
                          errorText: amountError,
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹', // Indian Rupee symbol
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: theme.textTheme.bodySmall?.color),
                                ),
                                const SizedBox(
                                    width:
                                        4), // Space between the symbol and the input
                              ],
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            try {
                              amount = num.parse(value);
                              amountError = null; // Clear error if valid
                            } catch (e) {
                              amountError = 'Invalid amount';
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Amount is required';
                          }
                          try {
                            double.parse(value);
                            return null;
                          } catch (e) {
                            return 'Invalid amount';
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        cursorColor: theme.colorScheme.tertiary,
                        decoration: InputDecoration(
                          floatingLabelStyle:
                              TextStyle(color: theme.colorScheme.tertiary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          labelText: 'Description',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: theme.colorScheme.tertiary)),
                          errorText: descriptionError,
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '>',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: theme.textTheme.bodySmall?.color),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          setState(() {
                            description = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null; // No error if the value is valid
                        },
                      ),

                      // Transaction Type Dropdown
                      DropdownButton<String>(
                        value: transactionType,
                        items: <String>['send', 'spend'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            transactionType = newValue!;
                            transactionTypeError = null; // Clear error if valid
                          });
                        },
                        isExpanded: true,
                        dropdownColor: theme.dialogBackgroundColor,
                      ),
                      if (transactionTypeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            transactionTypeError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Members Checkboxes
                      Expanded(
                        child: ListView(
                          children: cliqueProvider.currentClique!.members
                              .map((member) {
                            if (transactionType == "send") {
                              return RadioListTile(
                                activeColor: theme.colorScheme.tertiary,
                                title: Text(member.name,
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.titleSmall?.color)),
                                value: member.memberId,
                                groupValue: selectedMembers.isNotEmpty
                                    ? selectedMembers[0]['memberId']
                                    : null,
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedMembers.clear();
                                    selectedMembers.add({
                                      'memberId': value!,
                                      'name': member.name,
                                    });
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                              );
                            } else {
                              return CheckboxListTile(
                                activeColor: theme.colorScheme.tertiary,
                                title: Text(member.name,
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.titleSmall?.color)),
                                value: selectedMembers.any((element) =>
                                    element['memberId'] == member.memberId),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedMembers.add({
                                        'memberId': member.memberId,
                                        'name': member.name,
                                      });
                                    } else {
                                      selectedMembers.removeWhere((element) =>
                                          element['memberId'] ==
                                          member.memberId);
                                    }
                                  });
                                },
                              );
                            }
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Validation
                    bool isValid = true;

                    if (amount <= 0) {
                      setState(() {
                        amountError = 'Amount cannot be empty or zero';
                      });
                      isValid = false;
                    }
                    if (transactionType.isEmpty) {
                      setState(() {
                        transactionTypeError =
                            'Please select a transaction type';
                      });
                      isValid = false;
                    }

                    if (transactionType == "send" &&
                        selectedMembers.length > 1) {
                      setState(() {
                        transactionTypeError =
                            'When Send is Selected only one Member can be chosen';
                      });
                      isValid = false;
                    }

                    if (isValid) {
                      if (transactionType == "send") {
                        String type = transactionType;
                        List<Participantspost> participants = [
                          Participantspost(
                              id: selectedMembers[0]['memberId']!,
                              amount: amount)
                        ];
                        String cliqueId = cliqueProvider.currentClique!.id;
                        TransactionPostschema tSchema = TransactionPostschema(
                            cliqueId: cliqueId,
                            type: type,
                            participants: participants,
                            amount: amount,
                            description: description);
                        await TransactionPost.postData(
                            tSchema,
                            transactionProvider,
                            cliqueProvider,
                            cliqueListProvider);
                      } else {
                        context.push(
                          RoutersConstants.SPEND_TRANSACTION_SLIDER_PAGE,
                          extra: {
                            'selectedMembers': selectedMembers,
                            'amount': amount,
                            'description': description
                          },
                        );
                      }
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                  ),
                  child: Text(
                    'Create Transaction',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ReportsProvider reportsProvider = Provider.of<ReportsProvider>(context);
    // CliqueMediaProvider cliqueMediaProvider =
    //     Provider.of<CliqueMediaProvider>(context);
    ThemeData theme = Theme.of(context);
    return Consumer4<CliqueListProvider, CliqueProvider, TransactionProvider,
        CliqueMediaProvider>(
      builder: (context, cliqueListProvider, cliqueProvider,
          transactionProvider, cliqueMediaProvider, child) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                cliqueProvider.currentClique?.name ?? "Clique Ledger",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  onPressed: () {
                    context.push(RoutersConstants.CLIQUE_SETTINGS_ROUTE);
                  },
                  icon: Icon(
                    Icons.settings,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                )
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                TabBar(
                  indicatorColor: theme.colorScheme.secondary,
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Text("Transaction",
                          style: TextStyle(color: theme.colorScheme.tertiary)),
                    ),
                    Tab(
                      child: Text("Media",
                          style: TextStyle(color: theme.colorScheme.tertiary)),
                    ),
                    Tab(
                      child: Text("Report",
                          style: TextStyle(color: theme.colorScheme.tertiary)),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : transactionProvider
                                      .transactionMap[
                                          cliqueProvider.currentClique!.id]
                                      ?.isEmpty ??
                                  true
                              ? const Center(
                                  child: Text("No Transaction to show"))
                              : TransactionsTab(
                                  transactions:
                                      transactionProvider.transactionMap[
                                          cliqueProvider.currentClique!.id]!,
                                ),
                      CliqueMediaTab(cliqueMediaProvider: cliqueMediaProvider),
                      !isGenerateButtonClicked ||
                              !reportsProvider.reportList
                                  .containsKey(cliqueProvider.currentClique!.id)
                          ? const Center(child: Text('Report is Empty'))
                          : ReportTab(
                              cliqueProvider: cliqueProvider,
                              reportsProvider: reportsProvider),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: IndexedStack(
              index: _tabController.index,
              children: [
                FloatingActionButton(
                  heroTag: 'btn1',
                  onPressed: () => _createTransaction(
                    context,
                    cliqueProvider,
                    transactionProvider,
                    cliqueListProvider,
                  ),
                  tooltip: 'Create Transaction',
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'btn2',
                  onPressed: () {
                    // Handle action for the "Media" tab
                    pickImage.showImagePickerOption(context);
                  },
                  tooltip: 'Add Media',
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(
                    Icons.photo,
                    color: Colors.white,
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'btn3',
                  onPressed: () async {
                    await getAbstructReport(cliqueProvider.currentClique!.id,
                        reportsProvider, context);
                    setState(() {
                      isGenerateButtonClicked = true;
                    });
                  },
                  tooltip: 'Generate Report',
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(
                    Icons.report,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TransactionsTab extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionsTab({super.key, required this.transactions});

  void _checkTransaction(BuildContext context, Transaction t) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Transaction Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (t.type == "send") ...[
                      Text(
                        "Send Transaction",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${t.sender.name} : \u{20B9}${t.amount.toStringAsFixed(2)} paid to ${t.participants[0].name}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Spend Transaction",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${t.sender.name} Paid Total: \u{20B9}${t.amount.toStringAsFixed(2)} To -',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...t.participants
                          .map(
                            (p) => Text(
                              '${p.name} - \u{20B9}${p.partAmount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                          ,
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Description:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      t.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // ElevatedButton(
                    //   onPressed: () => {},
                    //   child: const Text(
                    //     "Verify",
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: const Color.fromARGB(255, 150, 4, 41),
                    //     minimumSize:
                    //         Size(double.infinity, 36), // Full-width button
                    //     padding: const EdgeInsets.symmetric(
                    //         vertical: 12), // Add vertical padding
                    //   ),
                    // ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Close',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Authservice.instance.profile!.cliqueLedgerAppUid;

    final ScrollController scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return ListView(
      controller: scrollController,
      children: transactions.map((tx) {
        bool isCurrentUserSender = tx.sender.userId == currentUserId;

        return Align(
          alignment: isCurrentUserSender
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: isCurrentUserSender
                ? const EdgeInsets.fromLTRB(60, 10, 5, 10)
                : const EdgeInsets.fromLTRB(5, 10, 60, 10),
            width: MediaQuery.of(context).size.width * 0.7,
            height: 140,
            child: Card(
              elevation: 10.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20.0),
                focusColor: theme.colorScheme.secondary,
                onTap: () => _checkTransaction(context, tx),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Text(
                          tx.sender.name,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 0,
                        child: Text(
                          '\u{20B9}${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 65,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14.0,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(tx.date.toLocal())}',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ReportTab extends StatefulWidget {
  final CliqueProvider cliqueProvider;
  final ReportsProvider reportsProvider;

  const ReportTab(
      {super.key, required this.cliqueProvider, required this.reportsProvider});

  @override
  // ignore: no_logic_in_create_state
  State<ReportTab> createState() => _ReportTabState(
      cliqueProvider: cliqueProvider, reportsProvider: reportsProvider);
}

class _ReportTabState extends State<ReportTab> {
  final CliqueProvider cliqueProvider;
  final ReportsProvider reportsProvider;
  final ReportApi reportApi = ReportApi();
  bool isLoading = false; // Loading state for the overall report

  _ReportTabState({
    required this.cliqueProvider,
    required this.reportsProvider,
  });

  Future<void> getDetailsReport(
      String cliqueId, String memberId, ReportsProvider reportsProvider) async {
    await reportApi.getDetailsReport(cliqueId, memberId, reportsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: reportsProvider
            .reportList[cliqueProvider.currentClique!.id]!.length,
        itemBuilder: (context, index) {
          AbstructReport report = reportsProvider
              .reportList[cliqueProvider.currentClique!.id]![index];
          return Column(
            children: [
              ExpansionTile(
                title: Row(
                  children: [
                    // Wrapping Text widgets with Expanded to prevent overflow
                    Expanded(
                      flex: 2,
                      child: Text(
                        report.userName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10), // Adjust width as necessary
                    Expanded(
                      flex: 1,
                      child: Text(
                        report.isDue ? "Due" : "Extra",
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: report.isDue
                              ? const Color.fromRGBO(222, 75, 95, 1)
                              : const Color.fromRGBO(99, 220, 190, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Adjust width as necessary
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${report.amount}',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.right, // Align text to the right
                      ),
                    ),
                  ],
                ),
                onExpansionChanged: (bool expanded) async {
                  if (expanded) {
                    report.detailsReport ??
                        await getDetailsReport(cliqueProvider.currentClique!.id,
                            report.memberId, reportsProvider);
                  }
                },
                children: report.detailsReport?.map((details) {
                      Color detailTileColor =
                          details.sendAmount == null || details.sendAmount == 0
                              ? const Color.fromRGBO(222, 75, 95, 0.2)
                              : const Color.fromRGBO(99, 220, 190, 0.2);

                      return ListTile(
                        tileColor: detailTileColor,
                        title: Text(
                          details.transactionId,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${DateFormat('yyyy-MM-dd HH:mm').format(details.date.toLocal())} - ${details.description}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          'Sent: ${details.sendAmount ?? 0}, Received: ${details.receiveAmount ?? 0}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }).toList() ??
                    [],
              ),
            ],
          );
        },
      ),
    );
  }
}
