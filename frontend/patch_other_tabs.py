import re

with open('lib/ui/features/dashboard/dashboard_view.dart', 'r') as f:
    content = f.read()

# Fire tab
fire_old = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Text("FIRE Milestones", style: theme.titleStyle),"""
fire_new = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
            Text("FIRE Milestones", style: theme.titleStyle),
          ]
        ),"""
content = content.replace(fire_old, fire_new)

# Calendar tab
cal_old = """        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dividend Calendar","""
cal_new = """        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: theme.text),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dividend Calendar","""
content = content.replace(cal_old, cal_new)

# History tab
hist_old = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Transaction History","""
hist_new = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: theme.text),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Transaction History","""
content = content.replace(hist_old, hist_new)

# Settings tab
set_old = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Text("Settings & Customization", style: theme.titleStyle),"""
set_new = """    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: theme.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 8),
            Text("Settings & Customization", style: theme.titleStyle),
          ]
        ),"""
content = content.replace(set_old, set_new)


with open('lib/ui/features/dashboard/dashboard_view.dart', 'w') as f:
    f.write(content)

